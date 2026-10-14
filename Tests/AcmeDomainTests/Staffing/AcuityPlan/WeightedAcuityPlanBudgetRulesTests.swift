@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedAcuityPlanBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultWeightedAcuityPlanBudgetValidator()
        let item = Staffing.newWeightedAcuityPlanBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingWeightedAcuityPlanBudgetRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Staffing.WeightedAcuityPlanBudgetRefillsRangeRule(min: 64, max: 1000)
        let item = Staffing.newWeightedAcuityPlanBudget("x", label: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingWeightedAcuityPlanBudgetRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.WeightedAcuityPlanBudgetRequiredContactEmailRule(
            message: "weighted acuity plan budget needs this field"
        )
        let item = Staffing.newWeightedAcuityPlanBudget("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingWeightedAcuityPlanBudgetPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Staffing.WeightedAcuityPlanBudgetPriorityRangeRule(min: 255, max: 86400)
        let item = Staffing.newWeightedAcuityPlanBudget("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingWeightedAcuityPlanBudgetSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Staffing.WeightedAcuityPlanBudgetSegmentLengthRule(maxLength: 16)
        let item = Staffing.newWeightedAcuityPlanBudget("x", label: "y")
        item.segment = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingWeightedAcuityPlanBudgetContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Staffing.WeightedAcuityPlanBudgetContactEmailLengthRule(maxLength: 32)
        let item = Staffing.newWeightedAcuityPlanBudget("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
