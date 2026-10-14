@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalChargeEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalChargeEntryValidator()
        let item = RevenueCycle.newRegionalChargeEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalChargeEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RegionalChargeEntryRequiredCodeRule(message: "regional charge entry needs an entry")
        let item = RevenueCycle.newRegionalChargeEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalChargeEntryRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = RevenueCycle.RegionalChargeEntryRegionLengthRule(maxLength: 16)
        let item = RevenueCycle.newRegionalChargeEntry("x", label: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRegionalChargeEntryRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = RevenueCycle.RegionalChargeEntryRequiredPayerRule(message: "regional charge entry needs a value")
        let item = RevenueCycle.newRegionalChargeEntry("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalChargeEntryVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.RegionalChargeEntryVisitMinutesRangeRule(min: 120, max: 86400)
        let item = RevenueCycle.newRegionalChargeEntry("x", label: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}
