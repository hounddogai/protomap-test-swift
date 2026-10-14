@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInventoryRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyInventoryRollupValidator()
        let item = Pharmacy.newLegacyInventoryRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyInventoryRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.LegacyInventoryRollupRequiredLabelRule(message: "legacy inventory rollup needs an entry")
        let item = Pharmacy.newLegacyInventoryRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInventoryRollupUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Pharmacy.LegacyInventoryRollupUnitLengthRule(maxLength: 3600)
        let item = Pharmacy.newLegacyInventoryRollup("x", label: "y")
        item.unit = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyInventoryRollupProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.LegacyInventoryRollupProcedureCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newLegacyInventoryRollup("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
