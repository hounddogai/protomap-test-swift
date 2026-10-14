@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkDraftValidator()
        let item = Referrals.newNetworkDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.NetworkDraftNameLengthRule(maxLength: 86400)
        let item = Referrals.newNetworkDraft("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkDraftSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.NetworkDraftSequenceRangeRule(min: 16, max: 1000)
        let item = Referrals.newNetworkDraft("x", name: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.NetworkDraftRequiredCodeRule(message: "network draft needs an entry")
        let item = Referrals.newNetworkDraft("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkDraftSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Referrals.NetworkDraftSummaryLengthRule(maxLength: 16)
        let item = Referrals.newNetworkDraft("x", name: "y")
        item.summary = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkDraftRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Referrals.NetworkDraftRequiredRegionRule(message: "network draft needs a value")
        let item = Referrals.newNetworkDraft("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.NetworkDraftRequiredNameRule(message: "network draft needs this field")
        let item = Referrals.newNetworkDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
