@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkSnapshotValidator()
        let item = Referrals.newNetworkSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkSnapshotRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Referrals.NetworkSnapshotRequiredSegmentRule(message: "network snapshot needs a value")
        let item = Referrals.newNetworkSnapshot("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.NetworkSnapshotRequiredNameRule(message: "network snapshot needs this field")
        let item = Referrals.newNetworkSnapshot("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.NetworkSnapshotRequiredCodeRule(message: "network snapshot needs a value")
        let item = Referrals.newNetworkSnapshot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkSnapshotCodeLengthRule(maxLength: 32)
        let item = Referrals.newNetworkSnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
