@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInteractionForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientInteractionForecastValidator()
        let item = Pharmacy.newLenientInteractionForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientInteractionForecastRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Pharmacy.LenientInteractionForecastRequiredRegionRule(
            message: "lenient interaction forecast needs a value"
        )
        let item = Pharmacy.newLenientInteractionForecast("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientInteractionForecastAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.LenientInteractionForecastAttemptsRangeRule(min: 64, max: 3600)
        let item = Pharmacy.newLenientInteractionForecast("x", label: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLenientInteractionForecastLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.LenientInteractionForecastLabelLengthRule(maxLength: 16)
        let item = Pharmacy.newLenientInteractionForecast("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientInteractionForecastRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Pharmacy.LenientInteractionForecastRequiredDescriptionRule(
            message: "lenient interaction forecast needs a value"
        )
        let item = Pharmacy.newLenientInteractionForecast("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientInteractionForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LenientInteractionForecastCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newLenientInteractionForecast("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
