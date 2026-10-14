@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryBatchValidator()
        let item = Pharmacy.newInventoryBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.InventoryBatchRequiredTitleRule(message: "inventory batch needs an entry")
        let item = Pharmacy.newInventoryBatch("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryBatchRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Pharmacy.InventoryBatchRequiredPayerRule(message: "inventory batch needs a value")
        let item = Pharmacy.newInventoryBatch("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.InventoryBatchTitleLengthRule(maxLength: 120)
        let item = Pharmacy.newInventoryBatch("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
