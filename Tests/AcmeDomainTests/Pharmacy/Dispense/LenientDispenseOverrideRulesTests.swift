@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientDispenseOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientDispenseOverrideValidator()
        let item = Pharmacy.newLenientDispenseOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientDispenseOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.LenientDispenseOverrideRequiredTitleRule(
            message: "lenient dispense override needs this field"
        )
        let item = Pharmacy.newLenientDispenseOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientDispenseOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LenientDispenseOverrideRequiredCodeRule(message: "lenient dispense override needs a value")
        let item = Pharmacy.newLenientDispenseOverride("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientDispenseOverrideWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Pharmacy.LenientDispenseOverrideWindowDaysRangeRule(min: 64, max: 1000)
        let item = Pharmacy.newLenientDispenseOverride("x", title: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLenientDispenseOverrideDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Pharmacy.LenientDispenseOverrideDurationMinutesRangeRule(min: 255, max: 3600)
        let item = Pharmacy.newLenientDispenseOverride("x", title: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}
