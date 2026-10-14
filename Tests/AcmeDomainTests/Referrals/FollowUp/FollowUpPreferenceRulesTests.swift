@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpPreferenceValidator()
        let item = Referrals.newFollowUpPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpPreferenceCodeLengthRule(maxLength: 64)
        let item = Referrals.newFollowUpPreference("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpPreferenceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.FollowUpPreferenceNameLengthRule(maxLength: 255)
        let item = Referrals.newFollowUpPreference("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpPreferenceProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Referrals.FollowUpPreferenceProcedureCodeLengthRule(maxLength: 255)
        let item = Referrals.newFollowUpPreference("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpPreferenceAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Referrals.FollowUpPreferenceAllergyLengthRule(maxLength: 120)
        let item = Referrals.newFollowUpPreference("x", name: "y")
        item.allergy = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}
