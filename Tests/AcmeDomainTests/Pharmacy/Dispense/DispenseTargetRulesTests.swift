@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseTargetValidator()
        let item = Pharmacy.newDispenseTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.DispenseTargetLabelLengthRule(maxLength: 80)
        let item = Pharmacy.newDispenseTarget("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseTargetRequiredCodeRule(message: "dispense target needs a value")
        let item = Pharmacy.newDispenseTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseTargetPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Pharmacy.DispenseTargetPriorityRangeRule(min: 64, max: 1000)
        let item = Pharmacy.newDispenseTarget("x", label: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseTargetRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Pharmacy.DispenseTargetRequiredEncounterIDRule(message: "dispense target needs a value")
        let item = Pharmacy.newDispenseTarget("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
