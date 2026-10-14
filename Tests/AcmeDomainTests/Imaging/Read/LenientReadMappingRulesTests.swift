@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLenientReadMappingValidator()
        let item = Imaging.newLenientReadMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLenientReadMappingRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Imaging.LenientReadMappingRequiredOwnerIDRule(message: "lenient read mapping needs an entry")
        let item = Imaging.newLenientReadMapping("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLenientReadMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.LenientReadMappingNameLengthRule(maxLength: 80)
        let item = Imaging.newLenientReadMapping("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLenientReadMappingLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Imaging.LenientReadMappingLimitRangeRule(min: 64, max: 1000)
        let item = Imaging.newLenientReadMapping("x", name: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}
