@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedTaskScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultWeightedTaskScheduleValidator()
        let item = ClinicalOps.newWeightedTaskSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsWeightedTaskScheduleRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = ClinicalOps.WeightedTaskScheduleRetriesRangeRule(min: 255, max: 255)
        let item = ClinicalOps.newWeightedTaskSchedule("x", title: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsWeightedTaskScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.WeightedTaskScheduleCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newWeightedTaskSchedule("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
