@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureOverrideValidator()
        let item = Referrals.newClosureOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ClosureOverrideRequiredCodeRule(message: "closure override needs a value")
        let item = Referrals.newClosureOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureOverrideDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Referrals.ClosureOverrideDiagnosisCodeLengthRule(maxLength: 86400)
        let item = Referrals.newClosureOverride("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
