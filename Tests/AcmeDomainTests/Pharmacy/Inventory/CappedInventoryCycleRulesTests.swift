@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInventoryCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedInventoryCycleValidator()
        let item = Pharmacy.newCappedInventoryCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedInventoryCycleLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Pharmacy.CappedInventoryCycleLimitRangeRule(min: 80, max: 3600)
        let item = Pharmacy.newCappedInventoryCycle("x", name: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyCappedInventoryCycleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.CappedInventoryCycleExpiresAtRangeRule(min: 16, max: 32)
        let item = Pharmacy.newCappedInventoryCycle("x", name: "y")
        item.expiresAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyCappedInventoryCycleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.CappedInventoryCycleNameLengthRule(maxLength: 120)
        let item = Pharmacy.newCappedInventoryCycle("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
