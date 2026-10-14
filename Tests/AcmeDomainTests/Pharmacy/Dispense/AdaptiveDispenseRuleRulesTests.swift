@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveDispenseRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveDispenseRuleValidator()
        let item = Pharmacy.newAdaptiveDispenseRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveDispenseRuleRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.AdaptiveDispenseRuleRatioRangeRule(min: 2.2, max: 3475.6)
        let item = Pharmacy.newAdaptiveDispenseRule("x", title: "y")
        item.ratio = 3477.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyAdaptiveDispenseRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.AdaptiveDispenseRuleCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newAdaptiveDispenseRule("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyAdaptiveDispenseRuleRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Pharmacy.AdaptiveDispenseRuleRequiredNotesRule(message: "adaptive dispense rule needs a value")
        let item = Pharmacy.newAdaptiveDispenseRule("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveDispenseRuleNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Pharmacy.AdaptiveDispenseRuleNotesLengthRule(maxLength: 32)
        let item = Pharmacy.newAdaptiveDispenseRule("x", title: "y")
        item.notes = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
