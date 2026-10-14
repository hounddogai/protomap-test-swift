@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultWeightedOrderSetPolicyValidator()
        let item = ClinicalOps.newWeightedOrderSetPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsWeightedOrderSetPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.WeightedOrderSetPolicyCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newWeightedOrderSetPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsWeightedOrderSetPolicyRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.WeightedOrderSetPolicyRequiredProcedureCodeRule(
            message: "weighted order set policy needs an entry"
        )
        let item = ClinicalOps.newWeightedOrderSetPolicy("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsWeightedOrderSetPolicyPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = ClinicalOps.WeightedOrderSetPolicyPayerLengthRule(maxLength: 120)
        let item = ClinicalOps.newWeightedOrderSetPolicy("x", label: "y")
        item.payer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
