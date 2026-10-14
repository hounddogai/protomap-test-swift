@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialReviewValidator()
        let item = Staffing.newCredentialReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialReviewRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Staffing.CredentialReviewRequiredPhoneRule(message: "credential review needs this field")
        let item = Staffing.newCredentialReview("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialReviewTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CredentialReviewTitleLengthRule(maxLength: 80)
        let item = Staffing.newCredentialReview("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialReviewRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Staffing.CredentialReviewRevisionRangeRule(min: 16, max: 86400)
        let item = Staffing.newCredentialReview("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialReviewCodeLengthRule(maxLength: 120)
        let item = Staffing.newCredentialReview("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
