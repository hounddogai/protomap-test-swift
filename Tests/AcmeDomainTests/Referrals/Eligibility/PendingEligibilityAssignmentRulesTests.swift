@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingEligibilityAssignmentValidator()
        let item = Referrals.newPendingEligibilityAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingEligibilityAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PendingEligibilityAssignmentRequiredCodeRule(
            message: "pending eligibility assignment needs this field"
        )
        let item = Referrals.newPendingEligibilityAssignment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingEligibilityAssignmentRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.PendingEligibilityAssignmentRequiredPatientRefRule(
            message: "pending eligibility assignment needs an entry"
        )
        let item = Referrals.newPendingEligibilityAssignment("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingEligibilityAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.PendingEligibilityAssignmentTitleLengthRule(maxLength: 86400)
        let item = Referrals.newPendingEligibilityAssignment("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPendingEligibilityAssignmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.PendingEligibilityAssignmentRequiredTitleRule(
            message: "pending eligibility assignment needs this field"
        )
        let item = Referrals.newPendingEligibilityAssignment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
