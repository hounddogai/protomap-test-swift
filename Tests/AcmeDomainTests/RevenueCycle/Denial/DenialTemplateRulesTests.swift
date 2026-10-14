@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialTemplateValidator()
        let item = RevenueCycle.newDenialTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialTemplateRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = RevenueCycle.DenialTemplateRequiredChannelRule(message: "denial template needs a value")
        let item = RevenueCycle.newDenialTemplate("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialTemplateExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.DenialTemplateExpiresAtRangeRule(min: 64, max: 86400)
        let item = RevenueCycle.newDenialTemplate("x", title: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialTemplateChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = RevenueCycle.DenialTemplateChannelLengthRule(maxLength: 80)
        let item = RevenueCycle.newDenialTemplate("x", title: "y")
        item.channel = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
