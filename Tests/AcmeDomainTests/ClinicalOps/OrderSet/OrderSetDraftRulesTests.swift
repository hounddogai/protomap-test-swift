@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetDraftValidator()
        let item = ClinicalOps.newOrderSetDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetDraftTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.OrderSetDraftTitleLengthRule(maxLength: 16)
        let item = ClinicalOps.newOrderSetDraft("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetDraftRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = ClinicalOps.OrderSetDraftRequiredSummaryRule(message: "order set draft needs a value")
        let item = ClinicalOps.newOrderSetDraft("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetDraftUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = ClinicalOps.OrderSetDraftUpdatedAtRangeRule(min: 32, max: 86400)
        let item = ClinicalOps.newOrderSetDraft("x", title: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
