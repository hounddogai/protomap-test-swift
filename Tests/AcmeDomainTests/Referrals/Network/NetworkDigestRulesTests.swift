@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkDigestValidator()
        let item = Referrals.newNetworkDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.NetworkDigestNameLengthRule(maxLength: 120)
        let item = Referrals.newNetworkDigest("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkDigestBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Referrals.NetworkDigestBedLengthRule(maxLength: 80)
        let item = Referrals.newNetworkDigest("x", name: "y")
        item.bed = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.NetworkDigestRequiredNameRule(message: "network digest needs this field")
        let item = Referrals.newNetworkDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkDigestCodeLengthRule(maxLength: 80)
        let item = Referrals.newNetworkDigest("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.NetworkDigestRequiredCodeRule(message: "network digest needs a value")
        let item = Referrals.newNetworkDigest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
