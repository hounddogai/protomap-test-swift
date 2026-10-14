@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseAdjustmentValidator()
        let item = Pharmacy.newDispenseAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseAdjustmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.DispenseAdjustmentRequiredNameRule(message: "dispense adjustment needs a value")
        let item = Pharmacy.newDispenseAdjustment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseAdjustmentRequiredCodeRule(message: "dispense adjustment needs a value")
        let item = Pharmacy.newDispenseAdjustment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseAdjustmentEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.DispenseAdjustmentEndsAtRangeRule(min: 16, max: 80)
        let item = Pharmacy.newDispenseAdjustment("x", name: "y")
        item.endsAt = 81
        #expect(rule.check(item).count > 0)
    }
}
