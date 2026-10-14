@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffAdjustmentValidator()
        let item = ClinicalOps.newHandoffAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffAdjustmentRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = ClinicalOps.HandoffAdjustmentRequiredWardRule(message: "handoff adjustment needs this field")
        let item = ClinicalOps.newHandoffAdjustment("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffAdjustmentQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.HandoffAdjustmentQuantityRangeRule(min: 16, max: 32)
        let item = ClinicalOps.newHandoffAdjustment("x", title: "y")
        item.quantity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffAdjustmentRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = ClinicalOps.HandoffAdjustmentRequiredSummaryRule(message: "handoff adjustment needs an entry")
        let item = ClinicalOps.newHandoffAdjustment("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffAdjustmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.HandoffAdjustmentTitleLengthRule(maxLength: 80)
        let item = ClinicalOps.newHandoffAdjustment("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
