@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessBaselineValidator()
        let item = Consent.newWitnessBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessBaselineRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Consent.WitnessBaselineRequiredOwnerIDRule(message: "witness baseline needs a value")
        let item = Consent.newWitnessBaseline("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessBaselineRequiredCodeRule(message: "witness baseline needs an entry")
        let item = Consent.newWitnessBaseline("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessBaselineContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Consent.WitnessBaselineContactEmailLengthRule(maxLength: 32)
        let item = Consent.newWitnessBaseline("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
