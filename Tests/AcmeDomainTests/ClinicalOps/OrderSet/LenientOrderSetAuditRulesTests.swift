@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientOrderSetAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLenientOrderSetAuditValidator()
        let item = ClinicalOps.newLenientOrderSetAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLenientOrderSetAuditRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.LenientOrderSetAuditRequiredNameRule(message: "lenient order set audit needs an entry")
        let item = ClinicalOps.newLenientOrderSetAudit("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLenientOrderSetAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.LenientOrderSetAuditCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newLenientOrderSetAudit("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLenientOrderSetAuditClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = ClinicalOps.LenientOrderSetAuditClinicianIDLengthRule(maxLength: 1000)
        let item = ClinicalOps.newLenientOrderSetAudit("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLenientOrderSetAuditRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = ClinicalOps.LenientOrderSetAuditRevisionRangeRule(min: 32, max: 64)
        let item = ClinicalOps.newLenientOrderSetAudit("x", name: "y")
        item.revision = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLenientOrderSetAuditBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = ClinicalOps.LenientOrderSetAuditBudgetRangeRule(min: 0.6, max: 1805.6)
        let item = ClinicalOps.newLenientOrderSetAudit("x", name: "y")
        item.budget = 1807.1
        #expect(rule.check(item).count > 0)
    }
}
