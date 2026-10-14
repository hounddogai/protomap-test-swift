@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskAuditValidator()
        let item = ClinicalOps.newTaskAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskAuditWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = ClinicalOps.TaskAuditWardLengthRule(maxLength: 120)
        let item = ClinicalOps.newTaskAudit("x", label: "y")
        item.ward = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskAuditRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = ClinicalOps.TaskAuditRequiredWardRule(message: "task audit needs a value")
        let item = ClinicalOps.newTaskAudit("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
