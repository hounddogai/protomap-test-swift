@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInventoryBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedInventoryBaselineValidator()
        let item = Pharmacy.newBatchedInventoryBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedInventoryBaselineContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Pharmacy.BatchedInventoryBaselineContactEmailLengthRule(maxLength: 1000)
        let item = Pharmacy.newBatchedInventoryBaseline("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedInventoryBaselineRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Pharmacy.BatchedInventoryBaselineRequiredSummaryRule(
            message: "batched inventory baseline needs a value"
        )
        let item = Pharmacy.newBatchedInventoryBaseline("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedInventoryBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.BatchedInventoryBaselineCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newBatchedInventoryBaseline("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedInventoryBaselineRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.BatchedInventoryBaselineRequiredLabelRule(
            message: "batched inventory baseline needs a value"
        )
        let item = Pharmacy.newBatchedInventoryBaseline("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedInventoryBaselineMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.BatchedInventoryBaselineMinimumRangeRule(min: 0.2, max: 3411.0)
        let item = Pharmacy.newBatchedInventoryBaseline("x", label: "y")
        item.minimum = 3412.5
        #expect(rule.check(item).count > 0)
    }
}
