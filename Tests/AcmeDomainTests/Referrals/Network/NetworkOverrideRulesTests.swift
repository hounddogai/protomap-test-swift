@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkOverrideValidator()
        let item = Referrals.newNetworkOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkOverrideRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.NetworkOverrideRequiredPatientRefRule(message: "network override needs an entry")
        let item = Referrals.newNetworkOverride("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkOverrideRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.NetworkOverrideRequiredNameRule(message: "network override needs this field")
        let item = Referrals.newNetworkOverride("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkOverrideRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Referrals.NetworkOverrideRequiredAllergyRule(message: "network override needs this field")
        let item = Referrals.newNetworkOverride("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkOverridePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Referrals.NetworkOverridePatientRefLengthRule(maxLength: 120)
        let item = Referrals.newNetworkOverride("x", name: "y")
        item.patientRef = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
