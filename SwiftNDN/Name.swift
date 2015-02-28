//
//  Name.swift
//  Swift-NDN
//
//  Created by Wentao Shang on 2/26/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class Name: Tlv {
    
    public class Component: Tlv {
        
        let value = [UInt8]()
        
        public override var block: Block? {
            return Block(type: TypeCode.NameComponent, bytes: self.value)
        }
        
        public init(bytes: [UInt8]) {
            self.value = bytes
        }
        
        public init?(block: Block) {
            super.init()
            if block.type != TypeCode.NameComponent {
                return nil
            }
            switch block.value {
            case .RawBytes(let bytes):
                self.value = bytes
            default: return nil
            }
        }
        
        public init?(url: String) {
            super.init()
            if let comps = NSURL(string: url)?.pathComponents? {
                if comps.count != 1 {
                    return nil
                }
                let unescaped = comps[0] as NSString
                if unescaped == "/" {
                    return nil
                }
                let cStr = unescaped.cStringUsingEncoding(NSASCIIStringEncoding)
                let cStrLen = unescaped.lengthOfBytesUsingEncoding(NSASCIIStringEncoding)
                if cStrLen == 0 {
                    return nil
                }
                var bytes = [UInt8]()
                bytes.reserveCapacity(cStrLen)
                for i in 0..<cStrLen {
                    bytes.append(UInt8(cStr[i]))
                }
                self.value = bytes
            } else {
                return nil
            }
        }
        
        public func toUri() -> String {
            var uri = NSString(bytes: self.value, length: self.value.count, encoding: NSASCIIStringEncoding)
            return (uri?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet()))!
        }
        
        // Return -1 if self < target; +1 if self > target; 0 if self == target
        public func compare(target: Component) -> Int {
            if self.value.count < target.value.count {
                return -1
            } else if self.value.count > target.value.count {
                return 1
            } else {
                for i in 0..<self.value.count {
                    if self.value[i] < target.value[i] {
                        return -1
                    }
                    if self.value[i] > target.value[i] {
                        return 1
                    }
                }
                return 0
            }
        }
    }
    
    var components = [Component]()
    
    public override var block: Block? {
        if components.count == 0 {
            return nil
        } else {
            var blk = Block(type: TypeCode.Name)
            for comp in self.components {
                if let compBlock = comp.block {
                    blk.appendBlock(compBlock)
                } else {
                    return nil
                }
            }
            return blk
        }
    }
    
    public var size: Int {
        return self.components.count
    }
    
    public var isEmpty: Bool {
        return self.components.isEmpty
    }
    
    public override init() {
        super.init()
    }

    public init?(block: Block) {
        super.init()
        if block.type != Tlv.TypeCode.Name {
            return nil
        }
        switch block.value {
        case .Blocks(let blocks):
            var comps = [Component]()
            for blk in blocks {
                if let c = Component(block: blk) {
                    comps.append(c)
                } else {
                    return nil
                }
            }
            self.components = comps
        default: return nil
        }
    }
    
    public init?(url: String) {
        super.init()
        if let comps = NSURL(string: url)?.pathComponents {
            if comps.count <= 1 {
                // Empty URL "/"
                return nil
            }
            for i in 1..<comps.count {
                let string = comps[i] as NSString
                let cStr = string.cStringUsingEncoding(NSASCIIStringEncoding)
                let cStrLen = string.lengthOfBytesUsingEncoding(NSASCIIStringEncoding)
                if cStrLen == 0 {
                    continue // skip empty string
                }
                var bytes = [UInt8]()
                bytes.reserveCapacity(cStrLen)
                for i in 0..<cStrLen {
                    bytes.append(UInt8(cStr[i]))
                }
                self.appendComponent(Component(bytes: bytes))
            }
        }
    }
    
    public func appendComponent(component: Component) {
        self.components.append(component)
    }
    
    public func getComponentByIndex(index: Int) -> Component? {
        return self.components[index]
    }

    public func toUri() -> String {
        if components.count == 0 {
            return "/"
        } else {
            var uri = ""
            for c in components {
                uri += "/\(c.toUri())"
            }
            return uri
        }
    }
    
    // Return -1 if self < target; +1 if self > target; 0 if self == target
    public func compare(target: Name) -> Int {
        let l = min(self.components.count, target.components.count)

        for i in 0..<l {
            if self.components[i] < target.components[i] {
                return -1
            }
            if self.components[i] > target.components[i] {
                return 1
            }
        }
        
        if self.components.count < target.components.count {
            return -1
        } else if self.components.count > target.components.count {
            return 1
        } else {
            return 0
        }
    }
}

public func == (lhs: Name.Component, rhs: Name.Component) -> Bool {
    return lhs.value == rhs.value
}

public func < (lhs: Name.Component, rhs: Name.Component) -> Bool {
    return lhs.compare(rhs) == -1
}

public func > (lhs: Name.Component, rhs: Name.Component) -> Bool {
    return lhs.compare(rhs) == 1
}

public func == (lhs: Name, rhs: Name) -> Bool {
    if lhs.components.count != rhs.components.count {
        return false
    }
    
    for i in 0..<lhs.components.count {
        if !(lhs.components[i] == rhs.components[i]) {
            return false
        }
    }
    
    return true
}

public func < (lhs: Name, rhs: Name) -> Bool {
    return lhs.compare(rhs) == -1
}

public func > (lhs: Name, rhs: Name) -> Bool {
    return lhs.compare(rhs) == 1
}