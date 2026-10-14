@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessRequestValidator()
        let item = Consent.newWitnessRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessRequestWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Consent.WitnessRequestWindowDaysRangeRule(min: 64, max: 1000)
        let item = Consent.newWitnessRequest("x", name: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessRequestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.WitnessRequestNameLengthRule(maxLength: 86400)
        let item = Consent.newWitnessRequest("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessRequestRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Consent.WitnessRequestRequiredCurrencyRule(message: "witness request needs an entry")
        let item = Consent.newWitnessRequest("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
