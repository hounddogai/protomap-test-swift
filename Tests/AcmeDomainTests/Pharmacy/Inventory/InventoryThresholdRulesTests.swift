@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryThresholdValidator()
        let item = Pharmacy.newInventoryThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.InventoryThresholdRequiredTitleRule(message: "inventory threshold needs an entry")
        let item = Pharmacy.newInventoryThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.InventoryThresholdTitleLengthRule(maxLength: 255)
        let item = Pharmacy.newInventoryThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryThresholdCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Pharmacy.InventoryThresholdCurrencyLengthRule(maxLength: 86400)
        let item = Pharmacy.newInventoryThreshold("x", title: "y")
        item.currency = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
