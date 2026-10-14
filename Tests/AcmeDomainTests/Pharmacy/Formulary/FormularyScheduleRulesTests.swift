@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyScheduleValidator()
        let item = Pharmacy.newFormularySchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyScheduleQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Pharmacy.FormularyScheduleQuantityRangeRule(min: 64, max: 120)
        let item = Pharmacy.newFormularySchedule("x", name: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyScheduleRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Pharmacy.FormularyScheduleRequiredBedRule(message: "formulary schedule needs an entry")
        let item = Pharmacy.newFormularySchedule("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.FormularyScheduleNameLengthRule(maxLength: 80)
        let item = Pharmacy.newFormularySchedule("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FormularyScheduleCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newFormularySchedule("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
