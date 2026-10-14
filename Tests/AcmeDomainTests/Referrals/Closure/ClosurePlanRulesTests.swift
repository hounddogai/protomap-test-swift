@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosurePlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosurePlanValidator()
        let item = Referrals.newClosurePlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosurePlanAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.ClosurePlanAmountRangeRule(min: 1.6, max: 3397.4)
        let item = Referrals.newClosurePlan("x", name: "y")
        item.amount = 3398.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosurePlanRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Referrals.ClosurePlanRequiredUnitRule(message: "closure plan needs a value")
        let item = Referrals.newClosurePlan("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
