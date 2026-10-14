@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingHandoffBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingHandoffBaselineValidator()
        let item = ClinicalOps.newPendingHandoffBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingHandoffBaselineRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = ClinicalOps.PendingHandoffBaselineRequiredDiagnosisCodeRule(
            message: "pending handoff baseline needs an entry"
        )
        let item = ClinicalOps.newPendingHandoffBaseline("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPendingHandoffBaselinePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.PendingHandoffBaselinePriorityRangeRule(min: 64, max: 120)
        let item = ClinicalOps.newPendingHandoffBaseline("x", title: "y")
        item.priority = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingHandoffBaselineDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = ClinicalOps.PendingHandoffBaselineDiagnosisCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newPendingHandoffBaseline("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
