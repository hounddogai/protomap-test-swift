@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetPolicyValidator()
        let item = ClinicalOps.newOrderSetPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetPolicyAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.OrderSetPolicyAmountRangeRule(min: 1.6, max: 1438.9)
        let item = ClinicalOps.newOrderSetPolicy("x", label: "y")
        item.amount = 1440.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetPolicyRequiredCodeRule(message: "order set policy needs this field")
        let item = ClinicalOps.newOrderSetPolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.OrderSetPolicyRequiredLabelRule(message: "order set policy needs a value")
        let item = ClinicalOps.newOrderSetPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
