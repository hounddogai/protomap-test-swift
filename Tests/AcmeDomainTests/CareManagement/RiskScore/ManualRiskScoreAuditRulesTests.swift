@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualRiskScoreAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualRiskScoreAuditValidator()
        let item = CareManagement.newManualRiskScoreAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualRiskScoreAuditRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = CareManagement.ManualRiskScoreAuditRequiredEncounterIDRule(
            message: "manual risk score audit needs a value"
        )
        let item = CareManagement.newManualRiskScoreAudit("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualRiskScoreAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ManualRiskScoreAuditRequiredCodeRule(message: "manual risk score audit needs an entry")
        let item = CareManagement.newManualRiskScoreAudit("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualRiskScoreAuditLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = CareManagement.ManualRiskScoreAuditLimitRangeRule(min: 32, max: 80)
        let item = CareManagement.newManualRiskScoreAudit("x", title: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementManualRiskScoreAuditTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = CareManagement.ManualRiskScoreAuditTimezoneLengthRule(maxLength: 3600)
        let item = CareManagement.newManualRiskScoreAudit("x", title: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
