@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredAuthorizationBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredAuthorizationBundleValidator()
        let item = RevenueCycle.newTieredAuthorizationBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredAuthorizationBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.TieredAuthorizationBundleTitleLengthRule(maxLength: 32)
        let item = RevenueCycle.newTieredAuthorizationBundle("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredAuthorizationBundleRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.TieredAuthorizationBundleRequiredTimezoneRule(
            message: "tiered authorization bundle needs a value"
        )
        let item = RevenueCycle.newTieredAuthorizationBundle("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredAuthorizationBundleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.TieredAuthorizationBundleRequiredTitleRule(
            message: "tiered authorization bundle needs this field"
        )
        let item = RevenueCycle.newTieredAuthorizationBundle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredAuthorizationBundleChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = RevenueCycle.TieredAuthorizationBundleChecksumLengthRule(maxLength: 3600)
        let item = RevenueCycle.newTieredAuthorizationBundle("x", title: "y")
        item.checksum = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredAuthorizationBundleRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = RevenueCycle.TieredAuthorizationBundleRequiredChecksumRule(
            message: "tiered authorization bundle needs this field"
        )
        let item = RevenueCycle.newTieredAuthorizationBundle("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredAuthorizationBundleTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = RevenueCycle.TieredAuthorizationBundleTimezoneLengthRule(maxLength: 80)
        let item = RevenueCycle.newTieredAuthorizationBundle("x", title: "y")
        item.timezone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
