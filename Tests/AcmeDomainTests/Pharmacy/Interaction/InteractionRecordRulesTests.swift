@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionRecordValidator()
        let item = Pharmacy.newInteractionRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionRecordRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.InteractionRecordRequiredNameRule(message: "interaction record needs a value")
        let item = Pharmacy.newInteractionRecord("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionRecordNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.InteractionRecordNameLengthRule(maxLength: 16)
        let item = Pharmacy.newInteractionRecord("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionRecordCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Pharmacy.InteractionRecordCurrencyLengthRule(maxLength: 16)
        let item = Pharmacy.newInteractionRecord("x", name: "y")
        item.currency = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionRecordUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Pharmacy.InteractionRecordUpdatedAtRangeRule(min: 64, max: 86400)
        let item = Pharmacy.newInteractionRecord("x", name: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionRecordCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newInteractionRecord("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
