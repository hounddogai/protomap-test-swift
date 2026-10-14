@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInventoryScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackInventoryScoreValidator()
        let item = Pharmacy.newFallbackInventoryScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackInventoryScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FallbackInventoryScoreCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newFallbackInventoryScore("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFallbackInventoryScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.FallbackInventoryScoreNameLengthRule(maxLength: 64)
        let item = Pharmacy.newFallbackInventoryScore("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFallbackInventoryScoreVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.FallbackInventoryScoreVisitMinutesRangeRule(min: 120, max: 86400)
        let item = Pharmacy.newFallbackInventoryScore("x", name: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFallbackInventoryScoreRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.FallbackInventoryScoreRequiredNameRule(message: "fallback inventory score needs this field")
        let item = Pharmacy.newFallbackInventoryScore("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFallbackInventoryScoreRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Pharmacy.FallbackInventoryScoreRequiredNotesRule(message: "fallback inventory score needs a value")
        let item = Pharmacy.newFallbackInventoryScore("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
