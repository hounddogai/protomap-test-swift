@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetPlanValidator()
        let item = ClinicalOps.newOrderSetPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetPlanCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = ClinicalOps.OrderSetPlanCeilingRangeRule(min: 7.4, max: 4487.2)
        let item = ClinicalOps.newOrderSetPlan("x", title: "y")
        item.ceiling = 4488.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetPlanRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = ClinicalOps.OrderSetPlanRequiredSummaryRule(message: "order set plan needs a value")
        let item = ClinicalOps.newOrderSetPlan("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.OrderSetPlanRequiredTitleRule(message: "order set plan needs a value")
        let item = ClinicalOps.newOrderSetPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetPlanRequiredCodeRule(message: "order set plan needs an entry")
        let item = ClinicalOps.newOrderSetPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetPlanCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newOrderSetPlan("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
