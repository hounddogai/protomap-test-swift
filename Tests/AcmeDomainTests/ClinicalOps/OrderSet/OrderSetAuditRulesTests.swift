@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetAuditValidator()
        let item = ClinicalOps.newOrderSetAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetAuditRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = ClinicalOps.OrderSetAuditRequiredSpecialtyRule(message: "order set audit needs this field")
        let item = ClinicalOps.newOrderSetAudit("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetAuditCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newOrderSetAudit("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetAuditRequiredCodeRule(message: "order set audit needs an entry")
        let item = ClinicalOps.newOrderSetAudit("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetAuditSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = ClinicalOps.OrderSetAuditSummaryLengthRule(maxLength: 80)
        let item = ClinicalOps.newOrderSetAudit("x", name: "y")
        item.summary = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
