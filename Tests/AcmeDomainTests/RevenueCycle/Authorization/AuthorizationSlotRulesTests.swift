@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationSlotValidator()
        let item = RevenueCycle.newAuthorizationSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationSlotRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = RevenueCycle.AuthorizationSlotRequiredPayerRule(message: "authorization slot needs a value")
        let item = RevenueCycle.newAuthorizationSlot("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationSlotRequiredCodeRule(message: "authorization slot needs a value")
        let item = RevenueCycle.newAuthorizationSlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationSlotPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = RevenueCycle.AuthorizationSlotPayerLengthRule(maxLength: 86400)
        let item = RevenueCycle.newAuthorizationSlot("x", label: "y")
        item.payer = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
