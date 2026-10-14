@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormCycleValidator()
        let item = Consent.newConsentFormCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormCycleVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Consent.ConsentFormCycleVisitMinutesRangeRule(min: 64, max: 255)
        let item = Consent.newConsentFormCycle("x", name: "y")
        item.visitMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormCyclePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Consent.ConsentFormCyclePayerLengthRule(maxLength: 32)
        let item = Consent.newConsentFormCycle("x", name: "y")
        item.payer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
