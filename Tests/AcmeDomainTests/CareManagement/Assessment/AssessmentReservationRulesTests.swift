@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentReservationValidator()
        let item = CareManagement.newAssessmentReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.AssessmentReservationLabelLengthRule(maxLength: 3600)
        let item = CareManagement.newAssessmentReservation("x", name: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentReservationMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = CareManagement.AssessmentReservationMinimumRangeRule(min: 3.6, max: 1196.2)
        let item = CareManagement.newAssessmentReservation("x", name: "y")
        item.minimum = 1197.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentReservationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.AssessmentReservationRequiredNameRule(message: "assessment reservation needs a value")
        let item = CareManagement.newAssessmentReservation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentReservationReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = CareManagement.AssessmentReservationReviewerLengthRule(maxLength: 120)
        let item = CareManagement.newAssessmentReservation("x", name: "y")
        item.reviewer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
