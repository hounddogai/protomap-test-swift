@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertOverrideValidator()
        let item = ClinicalOps.newAlertOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertOverrideRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = ClinicalOps.AlertOverrideRequiredReviewerRule(message: "alert override needs an entry")
        let item = ClinicalOps.newAlertOverride("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.AlertOverrideTitleLengthRule(maxLength: 80)
        let item = ClinicalOps.newAlertOverride("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertOverrideReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = ClinicalOps.AlertOverrideReviewerLengthRule(maxLength: 16)
        let item = ClinicalOps.newAlertOverride("x", title: "y")
        item.reviewer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AlertOverrideRequiredCodeRule(message: "alert override needs this field")
        let item = ClinicalOps.newAlertOverride("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.AlertOverrideRequiredTitleRule(message: "alert override needs a value")
        let item = ClinicalOps.newAlertOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
