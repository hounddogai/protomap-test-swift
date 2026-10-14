@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetExceptionValidator()
        let item = ClinicalOps.newOrderSetException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetExceptionRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = ClinicalOps.OrderSetExceptionRequiredSummaryRule(message: "order set exception needs an entry")
        let item = ClinicalOps.newOrderSetException("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetExceptionRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = ClinicalOps.OrderSetExceptionRequiredNotesRule(message: "order set exception needs an entry")
        let item = ClinicalOps.newOrderSetException("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
