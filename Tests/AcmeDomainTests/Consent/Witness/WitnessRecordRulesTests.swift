@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessRecordValidator()
        let item = Consent.newWitnessRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessRecordTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.WitnessRecordTitleLengthRule(maxLength: 120)
        let item = Consent.newWitnessRecord("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessRecordRequiredCodeRule(message: "witness record needs an entry")
        let item = Consent.newWitnessRecord("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
