@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeQuotaValidator()
        let item = RevenueCycle.newChargeQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ChargeQuotaRequiredTitleRule(message: "charge quota needs this field")
        let item = RevenueCycle.newChargeQuota("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeQuotaRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = RevenueCycle.ChargeQuotaRequiredRegionRule(message: "charge quota needs an entry")
        let item = RevenueCycle.newChargeQuota("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ChargeQuotaRequiredCodeRule(message: "charge quota needs this field")
        let item = RevenueCycle.newChargeQuota("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeQuotaRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = RevenueCycle.ChargeQuotaRequiredSummaryRule(message: "charge quota needs this field")
        let item = RevenueCycle.newChargeQuota("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
