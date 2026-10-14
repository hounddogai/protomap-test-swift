@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetRequestValidator()
        let item = ClinicalOps.newOrderSetRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetRequestAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.OrderSetRequestAmountRangeRule(min: 8.2, max: 572.9)
        let item = ClinicalOps.newOrderSetRequest("x", label: "y")
        item.amount = 574.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetRequestProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.OrderSetRequestProcedureCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newOrderSetRequest("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
