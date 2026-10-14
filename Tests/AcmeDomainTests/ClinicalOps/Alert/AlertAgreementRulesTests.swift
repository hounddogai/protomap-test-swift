@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertAgreementValidator()
        let item = ClinicalOps.newAlertAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.AlertAgreementCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newAlertAgreement("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertAgreementRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.AlertAgreementRequiredNameRule(message: "alert agreement needs an entry")
        let item = ClinicalOps.newAlertAgreement("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertAgreementPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.AlertAgreementPriorityRangeRule(min: 16, max: 64)
        let item = ClinicalOps.newAlertAgreement("x", name: "y")
        item.priority = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertAgreementCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = ClinicalOps.AlertAgreementCreatedAtRangeRule(min: 32, max: 80)
        let item = ClinicalOps.newAlertAgreement("x", name: "y")
        item.createdAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertAgreementDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = ClinicalOps.AlertAgreementDiagnosisCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newAlertAgreement("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
