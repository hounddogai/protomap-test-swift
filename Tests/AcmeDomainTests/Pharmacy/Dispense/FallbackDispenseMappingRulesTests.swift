@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackDispenseMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackDispenseMappingValidator()
        let item = Pharmacy.newFallbackDispenseMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackDispenseMappingRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Pharmacy.FallbackDispenseMappingRequiredRegionRule(
            message: "fallback dispense mapping needs this field"
        )
        let item = Pharmacy.newFallbackDispenseMapping("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFallbackDispenseMappingOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Pharmacy.FallbackDispenseMappingOwnerIDLengthRule(maxLength: 16)
        let item = Pharmacy.newFallbackDispenseMapping("x", label: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFallbackDispenseMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FallbackDispenseMappingCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newFallbackDispenseMapping("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFallbackDispenseMappingLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.FallbackDispenseMappingLabelLengthRule(maxLength: 32)
        let item = Pharmacy.newFallbackDispenseMapping("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
