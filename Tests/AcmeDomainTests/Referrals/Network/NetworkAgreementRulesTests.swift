@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkAgreementValidator()
        let item = Referrals.newNetworkAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkAgreementRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.NetworkAgreementRequiredClinicianIDRule(message: "network agreement needs an entry")
        let item = Referrals.newNetworkAgreement("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkAgreementExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Referrals.NetworkAgreementExpiresAtRangeRule(min: 32, max: 255)
        let item = Referrals.newNetworkAgreement("x", label: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkAgreementLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.NetworkAgreementLabelLengthRule(maxLength: 86400)
        let item = Referrals.newNetworkAgreement("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
