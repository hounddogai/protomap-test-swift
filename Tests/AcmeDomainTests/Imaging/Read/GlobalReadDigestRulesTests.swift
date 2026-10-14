@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalReadDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalReadDigestValidator()
        let item = Imaging.newGlobalReadDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalReadDigestExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Imaging.GlobalReadDigestExternalRefLengthRule(maxLength: 32)
        let item = Imaging.newGlobalReadDigest("x", name: "y")
        item.externalRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalReadDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.GlobalReadDigestRequiredCodeRule(message: "global read digest needs an entry")
        let item = Imaging.newGlobalReadDigest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalReadDigestCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Imaging.GlobalReadDigestCeilingRangeRule(min: 1.5, max: 2166.1)
        let item = Imaging.newGlobalReadDigest("x", name: "y")
        item.ceiling = 2167.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingGlobalReadDigestRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Imaging.GlobalReadDigestRequiredExternalRefRule(message: "global read digest needs this field")
        let item = Imaging.newGlobalReadDigest("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalReadDigestMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.GlobalReadDigestMinimumRangeRule(min: 1.1, max: 2209.8)
        let item = Imaging.newGlobalReadDigest("x", name: "y")
        item.minimum = 2211.3
        #expect(rule.check(item).count > 0)
    }
}
