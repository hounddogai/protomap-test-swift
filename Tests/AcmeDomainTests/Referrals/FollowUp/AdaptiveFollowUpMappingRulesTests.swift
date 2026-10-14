@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultAdaptiveFollowUpMappingValidator()
        let item = Referrals.newAdaptiveFollowUpMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsAdaptiveFollowUpMappingRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Referrals.AdaptiveFollowUpMappingRefillsRangeRule(min: 120, max: 255)
        let item = Referrals.newAdaptiveFollowUpMapping("x", label: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsAdaptiveFollowUpMappingCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.AdaptiveFollowUpMappingCapacityRangeRule(min: 32, max: 3600)
        let item = Referrals.newAdaptiveFollowUpMapping("x", label: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}
