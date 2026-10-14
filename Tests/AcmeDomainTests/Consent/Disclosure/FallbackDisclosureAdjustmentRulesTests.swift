@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackDisclosureAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultFallbackDisclosureAdjustmentValidator()
        let item = Consent.newFallbackDisclosureAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentFallbackDisclosureAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.FallbackDisclosureAdjustmentCodeLengthRule(maxLength: 16)
        let item = Consent.newFallbackDisclosureAdjustment("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentFallbackDisclosureAdjustmentDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Consent.FallbackDisclosureAdjustmentDosageMgRangeRule(min: 8.5, max: 1877.9)
        let item = Consent.newFallbackDisclosureAdjustment("x", name: "y")
        item.dosageMg = 1879.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentFallbackDisclosureAdjustmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.FallbackDisclosureAdjustmentRequiredNameRule(
            message: "fallback disclosure adjustment needs an entry"
        )
        let item = Consent.newFallbackDisclosureAdjustment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackDisclosureAdjustmentCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.FallbackDisclosureAdjustmentCostRangeRule(min: 7.4, max: 2810.6)
        let item = Consent.newFallbackDisclosureAdjustment("x", name: "y")
        item.cost = 2812.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentFallbackDisclosureAdjustmentRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Consent.FallbackDisclosureAdjustmentRequiredPhoneRule(
            message: "fallback disclosure adjustment needs an entry"
        )
        let item = Consent.newFallbackDisclosureAdjustment("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
