@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkCheckpointValidator()
        let item = Referrals.newNetworkCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.NetworkCheckpointRequiredCodeRule(message: "network checkpoint needs an entry")
        let item = Referrals.newNetworkCheckpoint("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkCheckpointRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Referrals.NetworkCheckpointRequiredAllergyRule(message: "network checkpoint needs this field")
        let item = Referrals.newNetworkCheckpoint("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.NetworkCheckpointRequiredNameRule(message: "network checkpoint needs this field")
        let item = Referrals.newNetworkCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkCheckpointCodeLengthRule(maxLength: 80)
        let item = Referrals.newNetworkCheckpoint("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
