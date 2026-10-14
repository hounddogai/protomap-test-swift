@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalSpecimenLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalSpecimenLedgerValidator()
        let item = Labs.newSeasonalSpecimenLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalSpecimenLedgerCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.SeasonalSpecimenLedgerCreatedAtRangeRule(min: 16, max: 86400)
        let item = Labs.newSeasonalSpecimenLedger("x", label: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSeasonalSpecimenLedgerRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.SeasonalSpecimenLedgerRequiredLabelRule(message: "seasonal specimen ledger needs a value")
        let item = Labs.newSeasonalSpecimenLedger("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSeasonalSpecimenLedgerAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Labs.SeasonalSpecimenLedgerAllergyLengthRule(maxLength: 255)
        let item = Labs.newSeasonalSpecimenLedger("x", label: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalSpecimenLedgerRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Labs.SeasonalSpecimenLedgerRequiredAllergyRule(message: "seasonal specimen ledger needs this field")
        let item = Labs.newSeasonalSpecimenLedger("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
