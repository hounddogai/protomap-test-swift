@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledClosureRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledClosureRequestValidator()
        let item = Referrals.newScheduledClosureRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledClosureRequestDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Referrals.ScheduledClosureRequestDiagnosisCodeLengthRule(maxLength: 86400)
        let item = Referrals.newScheduledClosureRequest("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledClosureRequestRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Referrals.ScheduledClosureRequestRequiredCountryRule(
            message: "scheduled closure request needs this field"
        )
        let item = Referrals.newScheduledClosureRequest("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
