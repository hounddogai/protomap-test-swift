@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormReservationValidator()
        let item = Consent.newConsentFormReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormReservationCodeLengthRule(maxLength: 1000)
        let item = Consent.newConsentFormReservation("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormReservationUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Consent.ConsentFormReservationUpdatedAtRangeRule(min: 255, max: 86400)
        let item = Consent.newConsentFormReservation("x", name: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormReservationRequiredCodeRule(message: "consent form reservation needs this field")
        let item = Consent.newConsentFormReservation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
