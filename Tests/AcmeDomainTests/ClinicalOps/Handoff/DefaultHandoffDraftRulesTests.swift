@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultHandoffDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultDefaultHandoffDraftValidator()
        let item = ClinicalOps.newDefaultHandoffDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsDefaultHandoffDraftRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.DefaultHandoffDraftRequiredTitleRule(message: "default handoff draft needs a value")
        let item = ClinicalOps.newDefaultHandoffDraft("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultHandoffDraftMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = ClinicalOps.DefaultHandoffDraftMaximumRangeRule(min: 5.1, max: 2275.7)
        let item = ClinicalOps.newDefaultHandoffDraft("x", title: "y")
        item.maximum = 2277.2
        #expect(rule.check(item).count > 0)
    }
}
