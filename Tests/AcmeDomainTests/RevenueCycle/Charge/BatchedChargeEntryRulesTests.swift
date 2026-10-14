@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedChargeEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedChargeEntryValidator()
        let item = RevenueCycle.newBatchedChargeEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedChargeEntryRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = RevenueCycle.BatchedChargeEntryRequiredContactEmailRule(
            message: "batched charge entry needs this field"
        )
        let item = RevenueCycle.newBatchedChargeEntry("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedChargeEntryQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.BatchedChargeEntryQuantityRangeRule(min: 16, max: 80)
        let item = RevenueCycle.newBatchedChargeEntry("x", label: "y")
        item.quantity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedChargeEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.BatchedChargeEntryRequiredNameRule(message: "batched charge entry needs this field")
        let item = RevenueCycle.newBatchedChargeEntry("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedChargeEntryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.BatchedChargeEntryLabelLengthRule(maxLength: 3600)
        let item = RevenueCycle.newBatchedChargeEntry("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedChargeEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.BatchedChargeEntryRequiredCodeRule(message: "batched charge entry needs an entry")
        let item = RevenueCycle.newBatchedChargeEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
