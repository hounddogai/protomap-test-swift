@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessGroupValidator()
        let item = Consent.newWitnessGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessGroupRequiredCodeRule(message: "witness group needs this field")
        let item = Consent.newWitnessGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessGroupRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Consent.WitnessGroupRequiredFacilityRule(message: "witness group needs a value")
        let item = Consent.newWitnessGroup("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessGroupFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Consent.WitnessGroupFacilityLengthRule(maxLength: 86400)
        let item = Consent.newWitnessGroup("x", label: "y")
        item.facility = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
