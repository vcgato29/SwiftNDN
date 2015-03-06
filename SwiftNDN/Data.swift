//
//  Data.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 3/3/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class Data: Tlv {
    
    public class MetaInfo: Tlv {
        
        public class ContentType: Tlv {
            
            struct Val {
                static let Blob: UInt64 = 0
                static let Link: UInt64 = 1
                static let Key:  UInt64 = 2
            }
            
            var value: UInt64 = Val.Blob
            
            public override var block: Block? {
                let bytes = Buffer.nonNegativeIntegerToByteArray(value)
                return Block(type: TypeCode.ContentType, bytes: bytes)
            }
            
            public override init() {
                super.init()
            }
            
            public init(value: UInt64) {
                self.value = value
            }
            
            public init?(block: Block) {
                super.init()
                if block.type != TypeCode.ContentType {
                    return nil
                }
                switch block.value {
                case .RawBytes(let bytes):
                    self.value = Buffer.byteArrayToNonNegativeInteger(bytes)
                default: return nil
                }
            }
        }
        
        public class FreshnessPeriod: Tlv {
            
            var value: UInt64 = 0
            
            public init(value: UInt64) {
                self.value = value
            }
            
            public init?(block: Block) {
                super.init()
                if block.type != TypeCode.FreshnessPeriod {
                    return nil
                }
                switch block.value {
                case .RawBytes(let bytes):
                    self.value = Buffer.byteArrayToNonNegativeInteger(bytes)
                default: return nil
                }
            }
            
            public override var block: Block? {
                let bytes = Buffer.nonNegativeIntegerToByteArray(value)
                return Block(type: TypeCode.FreshnessPeriod, bytes: bytes)
            }
        }
            
        var contentType: ContentType?
        var freshnessPeriod: FreshnessPeriod?
        
        public override init() {
            super.init()
        }
        
        public init?(block: Block) {
            super.init()
            if block.type != TypeCode.MetaInfo {
                return nil
            }
            switch block.value {
            case .Blocks(let blocks):
                //FIXME: enforce order during decoding?
                for blk in blocks {
                    if let ct = ContentType(block: blk) {
                        self.contentType = ct
                    } else if let fp = FreshnessPeriod(block: blk) {
                        self.freshnessPeriod = fp
                    }
                }
            default: return nil
            }
        }
        
        public override var block: Block? {
            var blocks = [Block]()
            if let ctb = self.contentType?.block {
                blocks.append(ctb)
            }
            if let fpb = self.freshnessPeriod?.block {
                blocks.append(fpb)
            }
            return Block(type: TypeCode.MetaInfo, blocks: blocks)
        }
    }
    
    public class Content: Tlv {
        
        var value = [UInt8]()
        
        public override var block: Block? {
            return Block(type: TypeCode.Content, bytes: value)
        }
        
        public override init() {
            super.init()
        }
        
        public init(value: [UInt8]) {
            self.value = value
        }
        
        public init?(block: Block) {
            super.init()
            if block.type != TypeCode.Content {
                return nil
            }
            switch block.value {
            case .RawBytes(let bytes):
                self.value = bytes
            default: return nil
            }
        }
    }
    
    public class SignatureInfo: Tlv {
        
        public class SignatureType: Tlv {
            
            public struct Val {
                public static let DigestSha256: UInt64 = 0
                public static let SignatureSha256WithRsa: UInt64 = 1
                public static let SignatureSha256WithEcdsa: UInt64 = 3
            }
            
            var value: UInt64 = Val.SignatureSha256WithRsa
            
            public override init() {
                super.init()
            }
            
            public init(value: UInt64) {
                self.value = value
            }
            
            public init?(block: Block) {
                super.init()
                if block.type != TypeCode.SignatureType {
                    return nil
                }
                switch block.value {
                case .RawBytes(let bytes):
                    self.value = Buffer.byteArrayToNonNegativeInteger(bytes)
                default: return nil
                }
            }
            
            public override var block: Block? {
                let bytes = Buffer.nonNegativeIntegerToByteArray(value)
                return Block(type: TypeCode.SignatureType, bytes: bytes)
            }
        }
        
        public class KeyLocator: Tlv {
            
            var name = Name()
            //TODO: support KeyDigest
            
            public override init() {
                super.init()
            }
            
            public init(name: Name) {
                self.name = name
            }
            
            public init?(block: Block) {
                super.init()
                if block.type != TypeCode.KeyLocator {
                    return nil
                }
                switch block.value {
                case .Blocks(let blocks):
                    if blocks.count != 1 {
                        return nil
                    }
                    if let n = Name(block: blocks[0]) {
                        self.name = n
                    } else {
                        return nil
                    }
                default: return nil
                }
            }
            
            public override var block: Block? {
                var blocks = [Block]()
                if let nb = self.name.block {
                    blocks.append(nb)
                    return Block(type: TypeCode.KeyLocator, blocks: blocks)
                } else {
                    return nil
                }
            }
        }
        
        public var signatureType = SignatureType()
        public var keyLocator: KeyLocator?
        
        public override init() {
            super.init()
        }
        
        public init?(block: Block) {
            super.init()
            if block.type != TypeCode.SignatureInfo {
                return nil
            }
            switch block.value {
            case .Blocks(let blocks):
                if blocks.count < 1 {
                    return nil
                }
                if let si = SignatureType(block: blocks[0]) {
                    self.signatureType = si
                } else {
                    return nil
                }
                if blocks.count == 2 {
                    if let kl = KeyLocator(block: blocks[1]) {
                        self.keyLocator = kl
                    }
                }
            default: return nil
            }
        }
        
        public override var block: Block? {
            var blocks = [Block]()
            if let stb = self.signatureType.block {
                blocks.append(stb)
            } else {
                return nil
            }
            if let klb = self.keyLocator?.block {
                blocks.append(klb)
            }
            return Block(type: TypeCode.SignatureInfo, blocks: blocks)
        }
    }
    
    public class SignatureValue: Tlv {
        
        var value = [UInt8]()
        
        public override var block: Block? {
            return Block(type: TypeCode.SignatureValue, bytes: value)
        }
        
        public override init() {
            super.init()
        }
        
        public init(value: [UInt8]) {
            self.value = value
        }
        
        public init?(block: Block) {
            super.init()
            if block.type != TypeCode.SignatureValue {
                return nil
            }
            switch block.value {
            case .RawBytes(let bytes):
                self.value = bytes
            default: return nil
            }
        }
    }
    
    public var name = Name()
    public var metaInfo = MetaInfo()
    public var content = Content()
    public var signatureInfo = SignatureInfo()
    public var signatureValue = SignatureValue()
    
    public override init() {
        super.init()
    }
    
    public init?(block: Block) {
        super.init()
        if block.type != TypeCode.Data {
            return nil
        }
        switch block.value {
        case .Blocks(let blocks):
            if blocks.count != 5 {
                return nil
            }
            if let name = Name(block: blocks[0]) {
                self.name = name
            } else {
                return nil
            }
            if let meta = MetaInfo(block: blocks[1]) {
                self.metaInfo = meta
            } else {
                return nil
            }
            if let content = Content(block: blocks[2]) {
                self.content = content
            } else {
                return nil
            }
            if let si = SignatureInfo(block: blocks[3]) {
                self.signatureInfo = si
            } else {
                return nil
            }
            if let sv = SignatureValue(block: blocks[4]) {
                self.signatureValue = sv
            } else {
                return nil
            }
        default: return nil
        }
    }
    
    public override var block: Block? {
        var blocks = [Block]()
        if let nb = self.name.block {
            blocks.append(nb)
        } else {
            return nil
        }
        if let mb = self.metaInfo.block {
            blocks.append(mb)
        } else {
            return nil
        }
        if let cb = self.content.block {
            blocks.append(cb)
        } else {
            return nil
        }
        if let sib = self.signatureInfo.block {
            blocks.append(sib)
        } else {
            return nil
        }
        if let svb = self.signatureValue.block {
            blocks.append(svb)
        } else {
            return nil
        }
        return Block(type: TypeCode.Data, blocks: blocks)
    }
    
    public func setContent(value: [UInt8]) {
        self.content = Content(value: value)
    }
    
    public func getContent() -> [UInt8] {
        return self.content.value
    }
    
    public func setFreshnessPeriod(value: UInt64) {
        self.metaInfo.freshnessPeriod = MetaInfo.FreshnessPeriod(value: value)
    }
    
    public func getFreshnessPeriod() -> UInt64? {
        return self.metaInfo.freshnessPeriod?.value
    }
    
    public func setContentType(value: UInt64) {
        self.metaInfo.contentType = MetaInfo.ContentType(value: value)
    }
    
    public func getContentType() -> UInt64? {
        return self.metaInfo.contentType?.value
    }
    
    func setSignature(value: [UInt8]) {
        self.signatureValue = SignatureValue(value: value)
    }
    
    func getSignature() -> [UInt8] {
        return self.signatureValue.value
    }
    
    public func getSignedPortion() -> [UInt8]? {
        if let nameEncode = self.name.wireEncode() {
            if let sigInfoEncode = self.signatureInfo.wireEncode() {
                let metaEncode = self.metaInfo.block!.wireEncode()
                let contentEncode = self.content.block!.wireEncode()
                return nameEncode + metaEncode + contentEncode + sigInfoEncode
            }
        }
        return nil
    }
    
    public class func wireDecode(bytes: [UInt8]) -> Data? {
        let (block, _) = Block.wireDecode(bytes)
        if let blk = block {
            return Data(block: blk)
        } else {
            return nil
        }
    }
}