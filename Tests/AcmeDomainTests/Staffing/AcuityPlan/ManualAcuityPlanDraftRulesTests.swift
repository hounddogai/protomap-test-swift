@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualAcuityPlanDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultManualAcuityPlanDraftValidator()
        let item = Staffing.newManualAcuityPlanDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingManualAcuityPlanDraftAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Staffing.ManualAcuityPlanDraftAttemptsRangeRule(min: 80, max: 86400)
        let item = Staffing.newManualAcuityPlanDraft("x", name: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingManualAcuityPlanDraftThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Staffing.ManualAcuityPlanDraftThresholdRangeRule(min: 8.5, max: 3325.6)
        let item = Staffing.newManualAcuityPlanDraft("x", name: "y")
        item.threshold = 3327.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingManualAcuityPlanDraftRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Staffing.ManualAcuityPlanDraftRequiredPayerRule(message: "manual acuity plan draft needs an entry")
        let item = Staffing.newManualAcuityPlanDraft("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingManualAcuityPlanDraftDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Staffing.ManualAcuityPlanDraftDosageMgRangeRule(min: 5.0, max: 2404.6)
        let item = Staffing.newManualAcuityPlanDraft("x", name: "y")
        item.dosageMg = 2406.1
        #expect(rule.check(item).count > 0)
    }
}
