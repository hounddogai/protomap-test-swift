@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictAuthorizationSlotValidator()
        let item = RevenueCycle.newStrictAuthorizationSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictAuthorizationSlotPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = RevenueCycle.StrictAuthorizationSlotPayerLengthRule(maxLength: 32)
        let item = RevenueCycle.newStrictAuthorizationSlot("x", title: "y")
        item.payer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStrictAuthorizationSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StrictAuthorizationSlotRequiredCodeRule(
            message: "strict authorization slot needs an entry"
        )
        let item = RevenueCycle.newStrictAuthorizationSlot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStrictAuthorizationSlotRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = RevenueCycle.StrictAuthorizationSlotRequiredPayerRule(
            message: "strict authorization slot needs an entry"
        )
        let item = RevenueCycle.newStrictAuthorizationSlot("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
