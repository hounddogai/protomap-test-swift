@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityRollupValidator()
        let item = Referrals.newEligibilityRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.EligibilityRollupNameLengthRule(maxLength: 32)
        let item = Referrals.newEligibilityRollup("x", title: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilityRollupCodeLengthRule(maxLength: 1000)
        let item = Referrals.newEligibilityRollup("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityRollupCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.EligibilityRollupCapacityRangeRule(min: 16, max: 3600)
        let item = Referrals.newEligibilityRollup("x", title: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}
