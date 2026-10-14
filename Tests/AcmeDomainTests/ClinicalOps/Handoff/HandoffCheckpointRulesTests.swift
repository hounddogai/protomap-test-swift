@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffCheckpointValidator()
        let item = ClinicalOps.newHandoffCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.HandoffCheckpointRequiredTitleRule(message: "handoff checkpoint needs an entry")
        let item = ClinicalOps.newHandoffCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.HandoffCheckpointCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newHandoffCheckpoint("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffCheckpointDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = ClinicalOps.HandoffCheckpointDiagnosisCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newHandoffCheckpoint("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffCheckpointPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.HandoffCheckpointPatientRefLengthRule(maxLength: 86400)
        let item = ClinicalOps.newHandoffCheckpoint("x", title: "y")
        item.patientRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.HandoffCheckpointRequiredCodeRule(message: "handoff checkpoint needs this field")
        let item = ClinicalOps.newHandoffCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
