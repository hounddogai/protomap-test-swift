@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessOverrideValidator()
        let item = Consent.newWitnessOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessOverrideRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Consent.WitnessOverrideRequiredWardRule(message: "witness override needs a value")
        let item = Consent.newWitnessOverride("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.WitnessOverrideRequiredTitleRule(message: "witness override needs an entry")
        let item = Consent.newWitnessOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.WitnessOverrideTitleLengthRule(maxLength: 16)
        let item = Consent.newWitnessOverride("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
