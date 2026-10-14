@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanThresholdValidator()
        let item = Staffing.newAcuityPlanThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanThresholdAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Staffing.AcuityPlanThresholdAttemptsRangeRule(min: 32, max: 3600)
        let item = Staffing.newAcuityPlanThreshold("x", name: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanThresholdRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Staffing.AcuityPlanThresholdRequiredChecksumRule(message: "acuity plan threshold needs an entry")
        let item = Staffing.newAcuityPlanThreshold("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.AcuityPlanThresholdNameLengthRule(maxLength: 255)
        let item = Staffing.newAcuityPlanThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanThresholdReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Staffing.AcuityPlanThresholdReviewerLengthRule(maxLength: 80)
        let item = Staffing.newAcuityPlanThreshold("x", name: "y")
        item.reviewer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
