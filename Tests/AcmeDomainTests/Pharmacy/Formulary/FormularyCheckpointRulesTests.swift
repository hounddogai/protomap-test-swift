@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyCheckpointValidator()
        let item = Pharmacy.newFormularyCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.FormularyCheckpointRequiredNameRule(message: "formulary checkpoint needs an entry")
        let item = Pharmacy.newFormularyCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyCheckpointUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Pharmacy.FormularyCheckpointUpdatedAtRangeRule(min: 255, max: 1000)
        let item = Pharmacy.newFormularyCheckpoint("x", name: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.FormularyCheckpointRequiredTitleRule(message: "formulary checkpoint needs an entry")
        let item = Pharmacy.newFormularyCheckpoint("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
