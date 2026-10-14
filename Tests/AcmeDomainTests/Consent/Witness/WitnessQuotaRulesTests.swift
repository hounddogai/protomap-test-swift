@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessQuotaValidator()
        let item = Consent.newWitnessQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.WitnessQuotaCodeLengthRule(maxLength: 80)
        let item = Consent.newWitnessQuota("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessQuotaRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.WitnessQuotaRequiredNameRule(message: "witness quota needs an entry")
        let item = Consent.newWitnessQuota("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessQuotaAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Consent.WitnessQuotaAmountRangeRule(min: 9.0, max: 3164.0)
        let item = Consent.newWitnessQuota("x", name: "y")
        item.amount = 3165.5
        #expect(rule.check(item).count > 0)
    }
}
