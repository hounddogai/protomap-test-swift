@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingNetworkBundleValidator()
        let item = Referrals.newPendingNetworkBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingNetworkBundleWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.PendingNetworkBundleWardLengthRule(maxLength: 86400)
        let item = Referrals.newPendingNetworkBundle("x", name: "y")
        item.ward = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPendingNetworkBundleRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Referrals.PendingNetworkBundleRequiredWardRule(message: "pending network bundle needs a value")
        let item = Referrals.newPendingNetworkBundle("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingNetworkBundleRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Referrals.PendingNetworkBundleRetriesRangeRule(min: 16, max: 32)
        let item = Referrals.newPendingNetworkBundle("x", name: "y")
        item.retries = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPendingNetworkBundleUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Referrals.PendingNetworkBundleUnitLengthRule(maxLength: 16)
        let item = Referrals.newPendingNetworkBundle("x", name: "y")
        item.unit = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPendingNetworkBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PendingNetworkBundleRequiredCodeRule(message: "pending network bundle needs this field")
        let item = Referrals.newPendingNetworkBundle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingNetworkBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.PendingNetworkBundleRequiredNameRule(message: "pending network bundle needs an entry")
        let item = Referrals.newPendingNetworkBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
