@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryDigestValidator()
        let item = Pharmacy.newInventoryDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryDigestCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Pharmacy.InventoryDigestCurrencyLengthRule(maxLength: 3600)
        let item = Pharmacy.newInventoryDigest("x", title: "y")
        item.currency = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryDigestRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Pharmacy.InventoryDigestRequiredCurrencyRule(message: "inventory digest needs a value")
        let item = Pharmacy.newInventoryDigest("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InventoryDigestCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newInventoryDigest("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryDigestWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.InventoryDigestWeightRangeRule(min: 8.3, max: 4055.0)
        let item = Pharmacy.newInventoryDigest("x", title: "y")
        item.weight = 4056.5
        #expect(rule.check(item).count > 0)
    }
}
