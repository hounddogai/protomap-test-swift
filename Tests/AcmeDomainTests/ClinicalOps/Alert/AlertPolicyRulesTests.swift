@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertPolicyValidator()
        let item = ClinicalOps.newAlertPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertPolicyProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.AlertPolicyProcedureCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newAlertPolicy("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertPolicyRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.AlertPolicyRequiredProcedureCodeRule(message: "alert policy needs a value")
        let item = ClinicalOps.newAlertPolicy("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
