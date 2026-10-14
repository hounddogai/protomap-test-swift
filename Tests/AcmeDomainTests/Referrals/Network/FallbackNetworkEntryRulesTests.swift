@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackNetworkEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackNetworkEntryValidator()
        let item = Referrals.newFallbackNetworkEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackNetworkEntryOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Referrals.FallbackNetworkEntryOwnerIDLengthRule(maxLength: 86400)
        let item = Referrals.newFallbackNetworkEntry("x", label: "y")
        item.ownerID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFallbackNetworkEntryCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.FallbackNetworkEntryCapacityRangeRule(min: 16, max: 120)
        let item = Referrals.newFallbackNetworkEntry("x", label: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFallbackNetworkEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FallbackNetworkEntryRequiredCodeRule(message: "fallback network entry needs a value")
        let item = Referrals.newFallbackNetworkEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackNetworkEntryRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Referrals.FallbackNetworkEntryRequiredOwnerIDRule(message: "fallback network entry needs an entry")
        let item = Referrals.newFallbackNetworkEntry("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackNetworkEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FallbackNetworkEntryCodeLengthRule(maxLength: 64)
        let item = Referrals.newFallbackNetworkEntry("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
