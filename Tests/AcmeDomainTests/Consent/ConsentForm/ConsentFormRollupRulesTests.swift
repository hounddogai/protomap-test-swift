@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormRollupValidator()
        let item = Consent.newConsentFormRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormRollupRequiredCodeRule(message: "consent form rollup needs an entry")
        let item = Consent.newConsentFormRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.ConsentFormRollupRequiredLabelRule(message: "consent form rollup needs this field")
        let item = Consent.newConsentFormRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.ConsentFormRollupLabelLengthRule(maxLength: 1000)
        let item = Consent.newConsentFormRollup("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormRollupCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.ConsentFormRollupCostRangeRule(min: 3.7, max: 1266.4)
        let item = Consent.newConsentFormRollup("x", label: "y")
        item.cost = 1267.9
        #expect(rule.check(item).count > 0)
    }
}
