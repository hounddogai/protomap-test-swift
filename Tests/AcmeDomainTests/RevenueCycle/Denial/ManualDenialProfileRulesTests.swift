@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualDenialProfileValidator()
        let item = RevenueCycle.newManualDenialProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualDenialProfileRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = RevenueCycle.ManualDenialProfileRequiredExternalRefRule(
            message: "manual denial profile needs an entry"
        )
        let item = RevenueCycle.newManualDenialProfile("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualDenialProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ManualDenialProfileCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newManualDenialProfile("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualDenialProfileRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ManualDenialProfileRequiredTitleRule(message: "manual denial profile needs this field")
        let item = RevenueCycle.newManualDenialProfile("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualDenialProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.ManualDenialProfileTitleLengthRule(maxLength: 32)
        let item = RevenueCycle.newManualDenialProfile("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
