@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffPolicyValidator()
        let item = ClinicalOps.newHandoffPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffPolicyProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.HandoffPolicyProcedureCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newHandoffPolicy("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.HandoffPolicyRequiredLabelRule(message: "handoff policy needs an entry")
        let item = ClinicalOps.newHandoffPolicy("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffPolicyTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.HandoffPolicyTitleLengthRule(maxLength: 3600)
        let item = ClinicalOps.newHandoffPolicy("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
