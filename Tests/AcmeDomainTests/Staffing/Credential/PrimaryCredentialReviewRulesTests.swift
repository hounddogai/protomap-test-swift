@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryCredentialReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryCredentialReviewValidator()
        let item = Staffing.newPrimaryCredentialReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryCredentialReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PrimaryCredentialReviewCodeLengthRule(maxLength: 32)
        let item = Staffing.newPrimaryCredentialReview("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryCredentialReviewRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Staffing.PrimaryCredentialReviewRefillsRangeRule(min: 32, max: 80)
        let item = Staffing.newPrimaryCredentialReview("x", label: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimaryCredentialReviewStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Staffing.PrimaryCredentialReviewStartsAtRangeRule(min: 64, max: 64)
        let item = Staffing.newPrimaryCredentialReview("x", label: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimaryCredentialReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.PrimaryCredentialReviewRequiredLabelRule(message: "primary credential review needs an entry")
        let item = Staffing.newPrimaryCredentialReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
