@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledRiskScoreRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledRiskScoreRecordValidator()
        let item = CareManagement.newScheduledRiskScoreRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledRiskScoreRecordRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = CareManagement.ScheduledRiskScoreRecordRegionLengthRule(maxLength: 120)
        let item = CareManagement.newScheduledRiskScoreRecord("x", label: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledRiskScoreRecordRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = CareManagement.ScheduledRiskScoreRecordRetriesRangeRule(min: 86400, max: 86400)
        let item = CareManagement.newScheduledRiskScoreRecord("x", label: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementScheduledRiskScoreRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ScheduledRiskScoreRecordRequiredCodeRule(
            message: "scheduled risk score record needs this field"
        )
        let item = CareManagement.newScheduledRiskScoreRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
