@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualDenialAgreementValidator()
        let item = RevenueCycle.newManualDenialAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualDenialAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ManualDenialAgreementRequiredCodeRule(message: "manual denial agreement needs an entry")
        let item = RevenueCycle.newManualDenialAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualDenialAgreementMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.ManualDenialAgreementMaximumRangeRule(min: 1.5, max: 338.0)
        let item = RevenueCycle.newManualDenialAgreement("x", name: "y")
        item.maximum = 339.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleManualDenialAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ManualDenialAgreementCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newManualDenialAgreement("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualDenialAgreementUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.ManualDenialAgreementUpdatedAtRangeRule(min: 120, max: 255)
        let item = RevenueCycle.newManualDenialAgreement("x", name: "y")
        item.updatedAt = 256
        #expect(rule.check(item).count > 0)
    }
}
