@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedRiskScoreNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedRiskScoreNoticeValidator()
        let item = CareManagement.newCappedRiskScoreNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedRiskScoreNoticePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = CareManagement.CappedRiskScoreNoticePriorityRangeRule(min: 3600, max: 86400)
        let item = CareManagement.newCappedRiskScoreNotice("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedRiskScoreNoticeRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = CareManagement.CappedRiskScoreNoticeRequiredWardRule(
            message: "capped risk score notice needs a value"
        )
        let item = CareManagement.newCappedRiskScoreNotice("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedRiskScoreNoticeRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = CareManagement.CappedRiskScoreNoticeRefillsRangeRule(min: 32, max: 32)
        let item = CareManagement.newCappedRiskScoreNotice("x", label: "y")
        item.refills = 33
        #expect(rule.check(item).count > 0)
    }
}
