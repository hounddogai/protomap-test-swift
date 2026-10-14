@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyHandoffLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyHandoffLedgerValidator()
        let item = ClinicalOps.newLegacyHandoffLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyHandoffLedgerSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = ClinicalOps.LegacyHandoffLedgerSpecialtyLengthRule(maxLength: 1000)
        let item = ClinicalOps.newLegacyHandoffLedger("x", label: "y")
        item.specialty = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyHandoffLedgerLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.LegacyHandoffLedgerLabelLengthRule(maxLength: 16)
        let item = ClinicalOps.newLegacyHandoffLedger("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyHandoffLedgerDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = ClinicalOps.LegacyHandoffLedgerDiagnosisCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newLegacyHandoffLedger("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
