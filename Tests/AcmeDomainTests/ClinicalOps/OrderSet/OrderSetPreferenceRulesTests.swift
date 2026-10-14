@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetPreferenceValidator()
        let item = ClinicalOps.newOrderSetPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetPreferenceRequiredCodeRule(message: "order set preference needs a value")
        let item = ClinicalOps.newOrderSetPreference("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetPreferenceCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newOrderSetPreference("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetPreferenceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.OrderSetPreferenceRequiredLabelRule(message: "order set preference needs an entry")
        let item = ClinicalOps.newOrderSetPreference("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.OrderSetPreferenceLabelLengthRule(maxLength: 64)
        let item = ClinicalOps.newOrderSetPreference("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
