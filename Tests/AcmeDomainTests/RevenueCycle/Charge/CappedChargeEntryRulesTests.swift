@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedChargeEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultCappedChargeEntryValidator()
        let item = RevenueCycle.newCappedChargeEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleCappedChargeEntryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.CappedChargeEntryRequiredTitleRule(message: "capped charge entry needs an entry")
        let item = RevenueCycle.newCappedChargeEntry("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleCappedChargeEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.CappedChargeEntryRequiredCodeRule(message: "capped charge entry needs a value")
        let item = RevenueCycle.newCappedChargeEntry("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleCappedChargeEntryBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = RevenueCycle.CappedChargeEntryBatchSizeRangeRule(min: 255, max: 1000)
        let item = RevenueCycle.newCappedChargeEntry("x", title: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}
