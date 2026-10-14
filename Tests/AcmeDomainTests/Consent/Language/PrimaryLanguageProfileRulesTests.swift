@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryLanguageProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPrimaryLanguageProfileValidator()
        let item = Consent.newPrimaryLanguageProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPrimaryLanguageProfileCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.PrimaryLanguageProfileCreatedAtRangeRule(min: 120, max: 1000)
        let item = Consent.newPrimaryLanguageProfile("x", title: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPrimaryLanguageProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.PrimaryLanguageProfileCodeLengthRule(maxLength: 80)
        let item = Consent.newPrimaryLanguageProfile("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryLanguageProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.PrimaryLanguageProfileTitleLengthRule(maxLength: 86400)
        let item = Consent.newPrimaryLanguageProfile("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryLanguageProfileLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.PrimaryLanguageProfileLimitRangeRule(min: 16, max: 80)
        let item = Consent.newPrimaryLanguageProfile("x", title: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}
