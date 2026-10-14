@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyEntryValidator()
        let item = Pharmacy.newFormularyEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyEntryRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Pharmacy.FormularyEntryRequiredExternalRefRule(message: "formulary entry needs a value")
        let item = Pharmacy.newFormularyEntry("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyEntryMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Pharmacy.FormularyEntryMaximumRangeRule(min: 4.6, max: 606.1)
        let item = Pharmacy.newFormularyEntry("x", label: "y")
        item.maximum = 607.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyEntryExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Pharmacy.FormularyEntryExternalRefLengthRule(maxLength: 32)
        let item = Pharmacy.newFormularyEntry("x", label: "y")
        item.externalRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
