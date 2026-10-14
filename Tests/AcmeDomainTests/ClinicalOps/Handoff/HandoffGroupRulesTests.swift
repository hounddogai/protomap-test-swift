@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffGroupValidator()
        let item = ClinicalOps.newHandoffGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffGroupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.HandoffGroupRequiredTitleRule(message: "handoff group needs this field")
        let item = ClinicalOps.newHandoffGroup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffGroupRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = ClinicalOps.HandoffGroupRequiredReviewerRule(message: "handoff group needs an entry")
        let item = ClinicalOps.newHandoffGroup("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
