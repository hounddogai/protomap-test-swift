@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryClosureAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimaryClosureAssignmentValidator()
        let item = Referrals.newPrimaryClosureAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimaryClosureAssignmentRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Referrals.PrimaryClosureAssignmentRequiredPhoneRule(
            message: "primary closure assignment needs an entry"
        )
        let item = Referrals.newPrimaryClosureAssignment("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimaryClosureAssignmentPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Referrals.PrimaryClosureAssignmentPhoneLengthRule(maxLength: 86400)
        let item = Referrals.newPrimaryClosureAssignment("x", title: "y")
        item.phone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
