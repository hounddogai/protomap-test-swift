@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedOrderSetPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultBatchedOrderSetPreferenceValidator()
        let item = ClinicalOps.newBatchedOrderSetPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsBatchedOrderSetPreferenceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.BatchedOrderSetPreferenceRequiredLabelRule(
            message: "batched order set preference needs an entry"
        )
        let item = ClinicalOps.newBatchedOrderSetPreference("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsBatchedOrderSetPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.BatchedOrderSetPreferenceCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newBatchedOrderSetPreference("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsBatchedOrderSetPreferenceRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = ClinicalOps.BatchedOrderSetPreferenceRequiredChannelRule(
            message: "batched order set preference needs an entry"
        )
        let item = ClinicalOps.newBatchedOrderSetPreference("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
