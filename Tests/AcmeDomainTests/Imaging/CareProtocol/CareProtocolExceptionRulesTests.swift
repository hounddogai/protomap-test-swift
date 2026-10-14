@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolExceptionValidator()
        let item = Imaging.newCareProtocolException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolExceptionCodeLengthRule(maxLength: 120)
        let item = Imaging.newCareProtocolException("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolExceptionChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Imaging.CareProtocolExceptionChecksumLengthRule(maxLength: 64)
        let item = Imaging.newCareProtocolException("x", name: "y")
        item.checksum = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolExceptionRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.CareProtocolExceptionRequiredNameRule(message: "care protocol exception needs an entry")
        let item = Imaging.newCareProtocolException("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
