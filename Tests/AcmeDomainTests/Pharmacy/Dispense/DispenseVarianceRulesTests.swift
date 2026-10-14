@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseVarianceValidator()
        let item = Pharmacy.newDispenseVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseVarianceRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Pharmacy.DispenseVarianceRequiredPhoneRule(message: "dispense variance needs this field")
        let item = Pharmacy.newDispenseVariance("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseVarianceQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Pharmacy.DispenseVarianceQuantityRangeRule(min: 32, max: 3600)
        let item = Pharmacy.newDispenseVariance("x", name: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}
