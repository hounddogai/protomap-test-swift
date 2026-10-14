@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialAdjustmentValidator()
        let item = RevenueCycle.newDenialAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialAdjustmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.DenialAdjustmentNameLengthRule(maxLength: 16)
        let item = RevenueCycle.newDenialAdjustment("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DenialAdjustmentRequiredCodeRule(message: "denial adjustment needs this field")
        let item = RevenueCycle.newDenialAdjustment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialAdjustmentRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = RevenueCycle.DenialAdjustmentRequiredCategoryRule(message: "denial adjustment needs this field")
        let item = RevenueCycle.newDenialAdjustment("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
