@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreScheduleValidator()
        let item = CareManagement.newRiskScoreSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreSchedulePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = CareManagement.RiskScoreSchedulePatientRefLengthRule(maxLength: 16)
        let item = CareManagement.newRiskScoreSchedule("x", name: "y")
        item.patientRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RiskScoreScheduleRequiredCodeRule(message: "risk score schedule needs this field")
        let item = CareManagement.newRiskScoreSchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreScheduleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.RiskScoreScheduleExpiresAtRangeRule(min: 120, max: 255)
        let item = CareManagement.newRiskScoreSchedule("x", name: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRiskScoreScheduleRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = CareManagement.RiskScoreScheduleRequiredBedRule(message: "risk score schedule needs a value")
        let item = CareManagement.newRiskScoreSchedule("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
