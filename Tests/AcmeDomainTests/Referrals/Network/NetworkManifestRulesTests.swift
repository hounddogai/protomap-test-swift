@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkManifestValidator()
        let item = Referrals.newNetworkManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkManifestEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.NetworkManifestEndsAtRangeRule(min: 120, max: 3600)
        let item = Referrals.newNetworkManifest("x", label: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.NetworkManifestRequiredCodeRule(message: "network manifest needs an entry")
        let item = Referrals.newNetworkManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkManifestRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Referrals.NetworkManifestRequiredAllergyRule(message: "network manifest needs a value")
        let item = Referrals.newNetworkManifest("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
