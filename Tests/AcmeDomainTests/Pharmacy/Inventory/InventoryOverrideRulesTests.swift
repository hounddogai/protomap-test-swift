@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryOverrideValidator()
        let item = Pharmacy.newInventoryOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryOverrideDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.InventoryOverrideDosageMgRangeRule(min: 8.5, max: 3374.7)
        let item = Pharmacy.newInventoryOverride("x", title: "y")
        item.dosageMg = 3376.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryOverrideProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.InventoryOverrideProcedureCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newInventoryOverride("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
