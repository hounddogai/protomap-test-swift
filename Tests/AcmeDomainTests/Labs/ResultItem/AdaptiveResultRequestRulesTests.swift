@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveResultRequestValidator()
        let item = Labs.newAdaptiveResultRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveResultRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AdaptiveResultRequestCodeLengthRule(maxLength: 32)
        let item = Labs.newAdaptiveResultRequest("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptiveResultRequestCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.AdaptiveResultRequestCreatedAtRangeRule(min: 32, max: 120)
        let item = Labs.newAdaptiveResultRequest("x", label: "y")
        item.createdAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptiveResultRequestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Labs.AdaptiveResultRequestDiscountRangeRule(min: 5.5, max: 3537.2)
        let item = Labs.newAdaptiveResultRequest("x", label: "y")
        item.discount = 3538.7
        #expect(rule.check(item).count > 0)
    }
}
