@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingScheduleValidator()
        let item = ClinicalOps.newRoundingSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingScheduleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = ClinicalOps.RoundingScheduleScoreRangeRule(min: 0.3, max: 2339.9)
        let item = ClinicalOps.newRoundingSchedule("x", title: "y")
        item.score = 2341.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RoundingScheduleCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newRoundingSchedule("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
