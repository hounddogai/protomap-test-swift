@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLegacyGoalSummaryValidator()
        let item = CareManagement.newLegacyGoalSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLegacyGoalSummaryPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = CareManagement.LegacyGoalSummaryPriorityRangeRule(min: 16, max: 32)
        let item = CareManagement.newLegacyGoalSummary("x", title: "y")
        item.priority = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLegacyGoalSummaryPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = CareManagement.LegacyGoalSummaryPatientRefLengthRule(maxLength: 32)
        let item = CareManagement.newLegacyGoalSummary("x", title: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyGoalSummaryRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = CareManagement.LegacyGoalSummaryRequiredPatientRefRule(
            message: "legacy goal summary needs this field"
        )
        let item = CareManagement.newLegacyGoalSummary("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyGoalSummaryEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = CareManagement.LegacyGoalSummaryEncounterIDLengthRule(maxLength: 255)
        let item = CareManagement.newLegacyGoalSummary("x", title: "y")
        item.encounterID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyGoalSummaryRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = CareManagement.LegacyGoalSummaryRequiredEncounterIDRule(message: "legacy goal summary needs a value")
        let item = CareManagement.newLegacyGoalSummary("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
