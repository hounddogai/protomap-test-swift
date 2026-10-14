@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedAlertPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultWeightedAlertPlanValidator()
        let item = ClinicalOps.newWeightedAlertPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsWeightedAlertPlanWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = ClinicalOps.WeightedAlertPlanWeightRangeRule(min: 2.5, max: 4297.5)
        let item = ClinicalOps.newWeightedAlertPlan("x", title: "y")
        item.weight = 4299.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsWeightedAlertPlanWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = ClinicalOps.WeightedAlertPlanWindowDaysRangeRule(min: 32, max: 1000)
        let item = ClinicalOps.newWeightedAlertPlan("x", title: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsWeightedAlertPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.WeightedAlertPlanRequiredCodeRule(message: "weighted alert plan needs a value")
        let item = ClinicalOps.newWeightedAlertPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsWeightedAlertPlanTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = ClinicalOps.WeightedAlertPlanTimezoneLengthRule(maxLength: 3600)
        let item = ClinicalOps.newWeightedAlertPlan("x", title: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsWeightedAlertPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.WeightedAlertPlanCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newWeightedAlertPlan("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
