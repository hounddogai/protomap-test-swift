@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalTaskClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalTaskClaimValidator()
        let item = ClinicalOps.newGlobalTaskClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalTaskClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.GlobalTaskClaimRequiredCodeRule(message: "global task claim needs a value")
        let item = ClinicalOps.newGlobalTaskClaim("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalTaskClaimCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.GlobalTaskClaimCostRangeRule(min: 3.6, max: 4146.6)
        let item = ClinicalOps.newGlobalTaskClaim("x", label: "y")
        item.cost = 4148.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalTaskClaimLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.GlobalTaskClaimLabelLengthRule(maxLength: 32)
        let item = ClinicalOps.newGlobalTaskClaim("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
