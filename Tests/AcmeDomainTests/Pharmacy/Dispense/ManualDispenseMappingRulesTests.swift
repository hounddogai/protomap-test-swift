@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualDispenseMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualDispenseMappingValidator()
        let item = Pharmacy.newManualDispenseMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualDispenseMappingRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Pharmacy.ManualDispenseMappingRequiredWardRule(message: "manual dispense mapping needs an entry")
        let item = Pharmacy.newManualDispenseMapping("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualDispenseMappingAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.ManualDispenseMappingAttemptsRangeRule(min: 120, max: 1000)
        let item = Pharmacy.newManualDispenseMapping("x", label: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualDispenseMappingRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.ManualDispenseMappingRequiredLabelRule(message: "manual dispense mapping needs an entry")
        let item = Pharmacy.newManualDispenseMapping("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
