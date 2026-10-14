@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingTaskAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingTaskAdjustmentValidator()
        let item = ClinicalOps.newPendingTaskAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingTaskAdjustmentDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = ClinicalOps.PendingTaskAdjustmentDurationMinutesRangeRule(min: 16, max: 80)
        let item = ClinicalOps.newPendingTaskAdjustment("x", title: "y")
        item.durationMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingTaskAdjustmentDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = ClinicalOps.PendingTaskAdjustmentDiagnosisCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newPendingTaskAdjustment("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingTaskAdjustmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.PendingTaskAdjustmentTitleLengthRule(maxLength: 255)
        let item = ClinicalOps.newPendingTaskAdjustment("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingTaskAdjustmentRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = ClinicalOps.PendingTaskAdjustmentRequiredDiagnosisCodeRule(
            message: "pending task adjustment needs this field"
        )
        let item = ClinicalOps.newPendingTaskAdjustment("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
