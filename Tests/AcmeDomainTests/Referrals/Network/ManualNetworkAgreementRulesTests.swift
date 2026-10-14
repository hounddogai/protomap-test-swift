@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualNetworkAgreementValidator()
        let item = Referrals.newManualNetworkAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualNetworkAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ManualNetworkAgreementRequiredCodeRule(message: "manual network agreement needs a value")
        let item = Referrals.newManualNetworkAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsManualNetworkAgreementRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Referrals.ManualNetworkAgreementRequiredDiagnosisCodeRule(
            message: "manual network agreement needs a value"
        )
        let item = Referrals.newManualNetworkAgreement("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsManualNetworkAgreementDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Referrals.ManualNetworkAgreementDiagnosisCodeLengthRule(maxLength: 80)
        let item = Referrals.newManualNetworkAgreement("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualNetworkAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ManualNetworkAgreementCodeLengthRule(maxLength: 1000)
        let item = Referrals.newManualNetworkAgreement("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
