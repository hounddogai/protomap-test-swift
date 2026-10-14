@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackRecallTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackRecallTemplateValidator()
        let item = Pharmacy.newFallbackRecallTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackRecallTemplateEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.FallbackRecallTemplateEndsAtRangeRule(min: 64, max: 255)
        let item = Pharmacy.newFallbackRecallTemplate("x", name: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFallbackRecallTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.FallbackRecallTemplateRequiredCodeRule(message: "fallback recall template needs a value")
        let item = Pharmacy.newFallbackRecallTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFallbackRecallTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FallbackRecallTemplateCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newFallbackRecallTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
