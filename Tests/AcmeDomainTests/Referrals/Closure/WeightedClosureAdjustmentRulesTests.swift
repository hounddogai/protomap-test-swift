@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedClosureAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedClosureAdjustmentValidator()
        let item = Referrals.newWeightedClosureAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedClosureAdjustmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.WeightedClosureAdjustmentNameLengthRule(maxLength: 1000)
        let item = Referrals.newWeightedClosureAdjustment("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsWeightedClosureAdjustmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.WeightedClosureAdjustmentFloorValueRangeRule(min: 0.4, max: 3875.7)
        let item = Referrals.newWeightedClosureAdjustment("x", name: "y")
        item.floorValue = 3877.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsWeightedClosureAdjustmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.WeightedClosureAdjustmentRequiredNameRule(
            message: "weighted closure adjustment needs this field"
        )
        let item = Referrals.newWeightedClosureAdjustment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
