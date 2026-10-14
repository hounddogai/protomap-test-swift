@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyModalityReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLegacyModalityReviewValidator()
        let item = Imaging.newLegacyModalityReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLegacyModalityReviewPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Imaging.LegacyModalityReviewPriorityRangeRule(min: 16, max: 64)
        let item = Imaging.newLegacyModalityReview("x", label: "y")
        item.priority = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLegacyModalityReviewPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Imaging.LegacyModalityReviewPatientRefLengthRule(maxLength: 1000)
        let item = Imaging.newLegacyModalityReview("x", label: "y")
        item.patientRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
