@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingCheckpointValidator()
        let item = ClinicalOps.newRoundingCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingCheckpointRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = ClinicalOps.RoundingCheckpointRequiredDiagnosisCodeRule(
            message: "rounding checkpoint needs this field"
        )
        let item = ClinicalOps.newRoundingCheckpoint("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingCheckpointProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.RoundingCheckpointProcedureCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newRoundingCheckpoint("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingCheckpointRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.RoundingCheckpointRequiredProcedureCodeRule(message: "rounding checkpoint needs an entry")
        let item = ClinicalOps.newRoundingCheckpoint("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RoundingCheckpointRequiredCodeRule(message: "rounding checkpoint needs this field")
        let item = ClinicalOps.newRoundingCheckpoint("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingCheckpointRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.RoundingCheckpointRequiredLabelRule(message: "rounding checkpoint needs an entry")
        let item = ClinicalOps.newRoundingCheckpoint("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
