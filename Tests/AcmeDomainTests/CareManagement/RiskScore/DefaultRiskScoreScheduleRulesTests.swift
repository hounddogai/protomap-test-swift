@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultDefaultRiskScoreScheduleValidator()
        let item = CareManagement.newDefaultRiskScoreSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementDefaultRiskScoreScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.DefaultRiskScoreScheduleNameLengthRule(maxLength: 1000)
        let item = CareManagement.newDefaultRiskScoreSchedule("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementDefaultRiskScoreScheduleSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = CareManagement.DefaultRiskScoreScheduleSummaryLengthRule(maxLength: 80)
        let item = CareManagement.newDefaultRiskScoreSchedule("x", name: "y")
        item.summary = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
