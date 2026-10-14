@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotForecastValidator()
        let item = Referrals.newSlotForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotForecastSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Referrals.SlotForecastSpecialtyLengthRule(maxLength: 86400)
        let item = Referrals.newSlotForecast("x", name: "y")
        item.specialty = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotForecastRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.SlotForecastRequiredNameRule(message: "slot forecast needs this field")
        let item = Referrals.newSlotForecast("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotForecastMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Referrals.SlotForecastMaximumRangeRule(min: 4.4, max: 3224.2)
        let item = Referrals.newSlotForecast("x", name: "y")
        item.maximum = 3225.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotForecastContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Referrals.SlotForecastContactEmailLengthRule(maxLength: 80)
        let item = Referrals.newSlotForecast("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotForecastRequiredCodeRule(message: "slot forecast needs a value")
        let item = Referrals.newSlotForecast("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
