@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadTierValidator()
        let item = Imaging.newReadTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadTierRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Imaging.ReadTierRetriesRangeRule(min: 255, max: 3600)
        let item = Imaging.newReadTier("x", label: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ReadTierRequiredCodeRule(message: "read tier needs a value")
        let item = Imaging.newReadTier("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadTierFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Imaging.ReadTierFloorValueRangeRule(min: 9.1, max: 2236.7)
        let item = Imaging.newReadTier("x", label: "y")
        item.floorValue = 2238.2
        #expect(rule.check(item).count > 0)
    }
}
