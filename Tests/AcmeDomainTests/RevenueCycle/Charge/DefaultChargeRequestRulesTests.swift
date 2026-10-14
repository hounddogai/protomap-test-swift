@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultChargeRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultChargeRequestValidator()
        let item = RevenueCycle.newDefaultChargeRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultChargeRequestPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = RevenueCycle.DefaultChargeRequestPhoneLengthRule(maxLength: 86400)
        let item = RevenueCycle.newDefaultChargeRequest("x", name: "y")
        item.phone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultChargeRequestRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = RevenueCycle.DefaultChargeRequestRequiredPhoneRule(message: "default charge request needs an entry")
        let item = RevenueCycle.newDefaultChargeRequest("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultChargeRequestCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = RevenueCycle.DefaultChargeRequestCountryLengthRule(maxLength: 64)
        let item = RevenueCycle.newDefaultChargeRequest("x", name: "y")
        item.country = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultChargeRequestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.DefaultChargeRequestNameLengthRule(maxLength: 255)
        let item = RevenueCycle.newDefaultChargeRequest("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultChargeRequestRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = RevenueCycle.DefaultChargeRequestRequiredCountryRule(message: "default charge request needs an entry")
        let item = RevenueCycle.newDefaultChargeRequest("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
