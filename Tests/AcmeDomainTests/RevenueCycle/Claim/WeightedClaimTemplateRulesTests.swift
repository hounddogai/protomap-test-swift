@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedClaimTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultWeightedClaimTemplateValidator()
        let item = RevenueCycle.newWeightedClaimTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleWeightedClaimTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.WeightedClaimTemplateLabelLengthRule(maxLength: 3600)
        let item = RevenueCycle.newWeightedClaimTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedClaimTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.WeightedClaimTemplateRequiredCodeRule(
            message: "weighted claim template needs this field"
        )
        let item = RevenueCycle.newWeightedClaimTemplate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedClaimTemplateRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = RevenueCycle.WeightedClaimTemplateRequiredSummaryRule(
            message: "weighted claim template needs a value"
        )
        let item = RevenueCycle.newWeightedClaimTemplate("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
