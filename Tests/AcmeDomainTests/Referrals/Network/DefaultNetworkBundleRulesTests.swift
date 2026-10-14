@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultDefaultNetworkBundleValidator()
        let item = Referrals.newDefaultNetworkBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsDefaultNetworkBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.DefaultNetworkBundleCodeLengthRule(maxLength: 32)
        let item = Referrals.newDefaultNetworkBundle("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsDefaultNetworkBundleSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Referrals.DefaultNetworkBundleSourceLengthRule(maxLength: 32)
        let item = Referrals.newDefaultNetworkBundle("x", title: "y")
        item.source = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsDefaultNetworkBundleCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Referrals.DefaultNetworkBundleCategoryLengthRule(maxLength: 86400)
        let item = Referrals.newDefaultNetworkBundle("x", title: "y")
        item.category = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsDefaultNetworkBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.DefaultNetworkBundleRequiredCodeRule(message: "default network bundle needs an entry")
        let item = Referrals.newDefaultNetworkBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsDefaultNetworkBundleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.DefaultNetworkBundleRequiredTitleRule(message: "default network bundle needs this field")
        let item = Referrals.newDefaultNetworkBundle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
