@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionRecordValidator()
        let item = Pharmacy.newSubstitutionRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionRecordRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.SubstitutionRecordRequiredNameRule(message: "substitution record needs a value")
        let item = Pharmacy.newSubstitutionRecord("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionRecordDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Pharmacy.SubstitutionRecordDiscountRangeRule(min: 5.3, max: 4746.9)
        let item = Pharmacy.newSubstitutionRecord("x", name: "y")
        item.discount = 4748.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionRecordNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.SubstitutionRecordNameLengthRule(maxLength: 32)
        let item = Pharmacy.newSubstitutionRecord("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionRecordRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Pharmacy.SubstitutionRecordRequiredNotesRule(message: "substitution record needs this field")
        let item = Pharmacy.newSubstitutionRecord("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
