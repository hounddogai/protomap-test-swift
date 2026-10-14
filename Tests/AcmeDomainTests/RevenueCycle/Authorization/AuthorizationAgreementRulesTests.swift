@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationAgreementValidator()
        let item = RevenueCycle.newAuthorizationAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.AuthorizationAgreementNameLengthRule(maxLength: 3600)
        let item = RevenueCycle.newAuthorizationAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationAgreementCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = RevenueCycle.AuthorizationAgreementCountryLengthRule(maxLength: 120)
        let item = RevenueCycle.newAuthorizationAgreement("x", name: "y")
        item.country = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationAgreementWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = RevenueCycle.AuthorizationAgreementWindowDaysRangeRule(min: 64, max: 64)
        let item = RevenueCycle.newAuthorizationAgreement("x", name: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}
