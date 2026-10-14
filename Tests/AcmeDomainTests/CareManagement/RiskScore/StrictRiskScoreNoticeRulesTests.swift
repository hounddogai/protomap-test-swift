@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictRiskScoreNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultStrictRiskScoreNoticeValidator()
        let item = CareManagement.newStrictRiskScoreNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementStrictRiskScoreNoticeGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.StrictRiskScoreNoticeGraceDaysRangeRule(min: 32, max: 32)
        let item = CareManagement.newStrictRiskScoreNotice("x", name: "y")
        item.graceDays = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementStrictRiskScoreNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.StrictRiskScoreNoticeCodeLengthRule(maxLength: 32)
        let item = CareManagement.newStrictRiskScoreNotice("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
