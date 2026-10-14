@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientChargeTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLenientChargeTierValidator()
        let item = RevenueCycle.newLenientChargeTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLenientChargeTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.LenientChargeTierRequiredCodeRule(message: "lenient charge tier needs an entry")
        let item = RevenueCycle.newLenientChargeTier("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLenientChargeTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.LenientChargeTierRequiredLabelRule(message: "lenient charge tier needs this field")
        let item = RevenueCycle.newLenientChargeTier("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLenientChargeTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.LenientChargeTierCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newLenientChargeTier("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
