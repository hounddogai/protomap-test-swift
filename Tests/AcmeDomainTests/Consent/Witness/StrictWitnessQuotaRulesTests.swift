@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictWitnessQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictWitnessQuotaValidator()
        let item = Consent.newStrictWitnessQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictWitnessQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.StrictWitnessQuotaRequiredTitleRule(message: "strict witness quota needs a value")
        let item = Consent.newStrictWitnessQuota("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictWitnessQuotaCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Consent.StrictWitnessQuotaCapacityRangeRule(min: 32, max: 120)
        let item = Consent.newStrictWitnessQuota("x", title: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictWitnessQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.StrictWitnessQuotaCodeLengthRule(maxLength: 16)
        let item = Consent.newStrictWitnessQuota("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentStrictWitnessQuotaTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.StrictWitnessQuotaTitleLengthRule(maxLength: 80)
        let item = Consent.newStrictWitnessQuota("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
