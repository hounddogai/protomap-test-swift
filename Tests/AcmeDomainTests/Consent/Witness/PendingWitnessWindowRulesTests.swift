@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingWitnessWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPendingWitnessWindowValidator()
        let item = Consent.newPendingWitnessWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPendingWitnessWindowRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.PendingWitnessWindowRequiredLocaleRule(message: "pending witness window needs this field")
        let item = Consent.newPendingWitnessWindow("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPendingWitnessWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.PendingWitnessWindowRequiredCodeRule(message: "pending witness window needs this field")
        let item = Consent.newPendingWitnessWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPendingWitnessWindowFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Consent.PendingWitnessWindowFacilityLengthRule(maxLength: 1000)
        let item = Consent.newPendingWitnessWindow("x", label: "y")
        item.facility = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
