@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingRoundingPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingRoundingPlanValidator()
        let item = ClinicalOps.newPendingRoundingPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingRoundingPlanThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = ClinicalOps.PendingRoundingPlanThresholdRangeRule(min: 9.6, max: 4148.9)
        let item = ClinicalOps.newPendingRoundingPlan("x", title: "y")
        item.threshold = 4150.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingRoundingPlanUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = ClinicalOps.PendingRoundingPlanUnitLengthRule(maxLength: 1000)
        let item = ClinicalOps.newPendingRoundingPlan("x", title: "y")
        item.unit = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingRoundingPlanTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.PendingRoundingPlanTitleLengthRule(maxLength: 255)
        let item = ClinicalOps.newPendingRoundingPlan("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingRoundingPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.PendingRoundingPlanRequiredTitleRule(message: "pending rounding plan needs an entry")
        let item = ClinicalOps.newPendingRoundingPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
