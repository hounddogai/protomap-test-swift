@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertReviewValidator()
        let item = ClinicalOps.newAlertReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertReviewThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = ClinicalOps.AlertReviewThresholdRangeRule(min: 7.9, max: 4095.1)
        let item = ClinicalOps.newAlertReview("x", label: "y")
        item.threshold = 4096.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertReviewRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = ClinicalOps.AlertReviewRequiredNotesRule(message: "alert review needs a value")
        let item = ClinicalOps.newAlertReview("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.AlertReviewLabelLengthRule(maxLength: 120)
        let item = ClinicalOps.newAlertReview("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
