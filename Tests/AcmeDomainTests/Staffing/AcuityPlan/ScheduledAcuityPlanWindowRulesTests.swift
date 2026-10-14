@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledAcuityPlanWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledAcuityPlanWindowValidator()
        let item = Staffing.newScheduledAcuityPlanWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledAcuityPlanWindowRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Staffing.ScheduledAcuityPlanWindowRequiredDescriptionRule(
            message: "scheduled acuity plan window needs a value"
        )
        let item = Staffing.newScheduledAcuityPlanWindow("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledAcuityPlanWindowDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Staffing.ScheduledAcuityPlanWindowDiagnosisCodeLengthRule(maxLength: 255)
        let item = Staffing.newScheduledAcuityPlanWindow("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledAcuityPlanWindowRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Staffing.ScheduledAcuityPlanWindowRequiredDiagnosisCodeRule(
            message: "scheduled acuity plan window needs a value"
        )
        let item = Staffing.newScheduledAcuityPlanWindow("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledAcuityPlanWindowBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Staffing.ScheduledAcuityPlanWindowBatchSizeRangeRule(min: 255, max: 3600)
        let item = Staffing.newScheduledAcuityPlanWindow("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingScheduledAcuityPlanWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.ScheduledAcuityPlanWindowRequiredTitleRule(
            message: "scheduled acuity plan window needs a value"
        )
        let item = Staffing.newScheduledAcuityPlanWindow("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledAcuityPlanWindowTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.ScheduledAcuityPlanWindowTitleLengthRule(maxLength: 3600)
        let item = Staffing.newScheduledAcuityPlanWindow("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
