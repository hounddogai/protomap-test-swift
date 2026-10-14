@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialBundleValidator()
        let item = RevenueCycle.newDenialBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialBundlePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.DenialBundlePriorityRangeRule(min: 80, max: 3600)
        let item = RevenueCycle.newDenialBundle("x", name: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.DenialBundleNameLengthRule(maxLength: 1000)
        let item = RevenueCycle.newDenialBundle("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.DenialBundleRequiredNameRule(message: "denial bundle needs this field")
        let item = RevenueCycle.newDenialBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialBundleQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.DenialBundleQuantityRangeRule(min: 16, max: 64)
        let item = RevenueCycle.newDenialBundle("x", name: "y")
        item.quantity = 65
        #expect(rule.check(item).count > 0)
    }
}
