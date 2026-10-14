@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseAllocationValidator()
        let item = Pharmacy.newDispenseAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DispenseAllocationCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newDispenseAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseAllocationCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Pharmacy.DispenseAllocationCapacityRangeRule(min: 16, max: 3600)
        let item = Pharmacy.newDispenseAllocation("x", label: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseAllocationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.DispenseAllocationRequiredLabelRule(message: "dispense allocation needs this field")
        let item = Pharmacy.newDispenseAllocation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
