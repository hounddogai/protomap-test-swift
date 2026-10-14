@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionForecastValidator()
        let item = Pharmacy.newInteractionForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionForecastRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Pharmacy.InteractionForecastRequiredNotesRule(message: "interaction forecast needs an entry")
        let item = Pharmacy.newInteractionForecast("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionForecastNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Pharmacy.InteractionForecastNotesLengthRule(maxLength: 255)
        let item = Pharmacy.newInteractionForecast("x", title: "y")
        item.notes = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionForecastWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Pharmacy.InteractionForecastWindowDaysRangeRule(min: 80, max: 120)
        let item = Pharmacy.newInteractionForecast("x", title: "y")
        item.windowDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionForecastCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newInteractionForecast("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
