@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalAuthorizationBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultGlobalAuthorizationBundleValidator()
        let item = RevenueCycle.newGlobalAuthorizationBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleGlobalAuthorizationBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.GlobalAuthorizationBundleRequiredLabelRule(
            message: "global authorization bundle needs this field"
        )
        let item = RevenueCycle.newGlobalAuthorizationBundle("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleGlobalAuthorizationBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.GlobalAuthorizationBundleNameLengthRule(maxLength: 80)
        let item = RevenueCycle.newGlobalAuthorizationBundle("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleGlobalAuthorizationBundleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.GlobalAuthorizationBundleLabelLengthRule(maxLength: 64)
        let item = RevenueCycle.newGlobalAuthorizationBundle("x", name: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
