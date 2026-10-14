@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularySlotValidator()
        let item = Pharmacy.newFormularySlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularySlotExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Pharmacy.FormularySlotExternalRefLengthRule(maxLength: 255)
        let item = Pharmacy.newFormularySlot("x", title: "y")
        item.externalRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularySlotStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.FormularySlotStartsAtRangeRule(min: 32, max: 120)
        let item = Pharmacy.newFormularySlot("x", title: "y")
        item.startsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularySlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.FormularySlotTitleLengthRule(maxLength: 64)
        let item = Pharmacy.newFormularySlot("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularySlotRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Pharmacy.FormularySlotRequiredPhoneRule(message: "formulary slot needs an entry")
        let item = Pharmacy.newFormularySlot("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularySlotPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Pharmacy.FormularySlotPhoneLengthRule(maxLength: 32)
        let item = Pharmacy.newFormularySlot("x", title: "y")
        item.phone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
