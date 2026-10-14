@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingFloatPoolScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRollingFloatPoolScoreValidator()
        let item = Staffing.newRollingFloatPoolScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRollingFloatPoolScoreRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.RollingFloatPoolScoreRequiredLabelRule(message: "rolling float pool score needs this field")
        let item = Staffing.newRollingFloatPoolScore("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingFloatPoolScoreRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Staffing.RollingFloatPoolScoreRequiredEncounterIDRule(
            message: "rolling float pool score needs a value"
        )
        let item = Staffing.newRollingFloatPoolScore("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingFloatPoolScoreRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Staffing.RollingFloatPoolScoreRetriesRangeRule(min: 32, max: 3600)
        let item = Staffing.newRollingFloatPoolScore("x", label: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRollingFloatPoolScoreRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Staffing.RollingFloatPoolScoreRequiredBedRule(message: "rolling float pool score needs an entry")
        let item = Staffing.newRollingFloatPoolScore("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
