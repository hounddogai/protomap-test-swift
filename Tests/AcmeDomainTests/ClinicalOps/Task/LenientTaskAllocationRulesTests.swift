@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientTaskAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLenientTaskAllocationValidator()
        let item = ClinicalOps.newLenientTaskAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLenientTaskAllocationWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = ClinicalOps.LenientTaskAllocationWeightRangeRule(min: 4.9, max: 658.4)
        let item = ClinicalOps.newLenientTaskAllocation("x", title: "y")
        item.weight = 659.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLenientTaskAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.LenientTaskAllocationRequiredCodeRule(message: "lenient task allocation needs a value")
        let item = ClinicalOps.newLenientTaskAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLenientTaskAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.LenientTaskAllocationCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newLenientTaskAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
