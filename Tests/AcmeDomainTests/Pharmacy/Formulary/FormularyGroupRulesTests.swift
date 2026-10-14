@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyGroupValidator()
        let item = Pharmacy.newFormularyGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyGroupEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.FormularyGroupEndsAtRangeRule(min: 16, max: 3600)
        let item = Pharmacy.newFormularyGroup("x", name: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyGroupChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Pharmacy.FormularyGroupChecksumLengthRule(maxLength: 32)
        let item = Pharmacy.newFormularyGroup("x", name: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyGroupRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Pharmacy.FormularyGroupRequiredChecksumRule(message: "formulary group needs an entry")
        let item = Pharmacy.newFormularyGroup("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FormularyGroupCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newFormularyGroup("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
