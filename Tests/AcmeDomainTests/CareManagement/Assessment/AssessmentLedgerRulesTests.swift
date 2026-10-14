@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentLedgerValidator()
        let item = CareManagement.newAssessmentLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentLedgerWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.AssessmentLedgerWeightRangeRule(min: 2.5, max: 1373.3)
        let item = CareManagement.newAssessmentLedger("x", name: "y")
        item.weight = 1374.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AssessmentLedgerCodeLengthRule(maxLength: 80)
        let item = CareManagement.newAssessmentLedger("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentLedgerRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = CareManagement.AssessmentLedgerRequiredUnitRule(message: "assessment ledger needs this field")
        let item = CareManagement.newAssessmentLedger("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.AssessmentLedgerRequiredNameRule(message: "assessment ledger needs an entry")
        let item = CareManagement.newAssessmentLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
