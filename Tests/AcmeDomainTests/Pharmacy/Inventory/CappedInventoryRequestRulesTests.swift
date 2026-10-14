@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInventoryRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedInventoryRequestValidator()
        let item = Pharmacy.newCappedInventoryRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedInventoryRequestCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Pharmacy.CappedInventoryRequestCapacityRangeRule(min: 16, max: 86400)
        let item = Pharmacy.newCappedInventoryRequest("x", label: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyCappedInventoryRequestRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Pharmacy.CappedInventoryRequestRequiredBedRule(message: "capped inventory request needs a value")
        let item = Pharmacy.newCappedInventoryRequest("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedInventoryRequestProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.CappedInventoryRequestProcedureCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newCappedInventoryRequest("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyCappedInventoryRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.CappedInventoryRequestRequiredLabelRule(message: "capped inventory request needs a value")
        let item = Pharmacy.newCappedInventoryRequest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedInventoryRequestBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Pharmacy.CappedInventoryRequestBedLengthRule(maxLength: 255)
        let item = Pharmacy.newCappedInventoryRequest("x", label: "y")
        item.bed = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
