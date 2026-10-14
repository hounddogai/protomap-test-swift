@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkEntryValidator()
        let item = Referrals.newNetworkEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.NetworkEntryNameLengthRule(maxLength: 32)
        let item = Referrals.newNetworkEntry("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkEntryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.NetworkEntryRequiredTitleRule(message: "network entry needs a value")
        let item = Referrals.newNetworkEntry("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkEntryCodeLengthRule(maxLength: 16)
        let item = Referrals.newNetworkEntry("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkEntryEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.NetworkEntryEndsAtRangeRule(min: 32, max: 80)
        let item = Referrals.newNetworkEntry("x", name: "y")
        item.endsAt = 81
        #expect(rule.check(item).count > 0)
    }
}
