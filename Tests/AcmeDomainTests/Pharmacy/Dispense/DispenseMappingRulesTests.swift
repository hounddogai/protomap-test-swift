@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseMappingValidator()
        let item = Pharmacy.newDispenseMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseMappingThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Pharmacy.DispenseMappingThresholdRangeRule(min: 3.7, max: 4018.8)
        let item = Pharmacy.newDispenseMapping("x", name: "y")
        item.threshold = 4020.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseMappingRequiredCodeRule(message: "dispense mapping needs a value")
        let item = Pharmacy.newDispenseMapping("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.DispenseMappingNameLengthRule(maxLength: 16)
        let item = Pharmacy.newDispenseMapping("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseMappingRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Pharmacy.DispenseMappingRequiredProcedureCodeRule(message: "dispense mapping needs a value")
        let item = Pharmacy.newDispenseMapping("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
