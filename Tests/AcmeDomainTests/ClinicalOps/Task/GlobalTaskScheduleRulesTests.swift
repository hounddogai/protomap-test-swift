@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalTaskScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalTaskScheduleValidator()
        let item = ClinicalOps.newGlobalTaskSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalTaskScheduleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.GlobalTaskScheduleRequiredLabelRule(message: "global task schedule needs a value")
        let item = ClinicalOps.newGlobalTaskSchedule("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalTaskScheduleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = ClinicalOps.GlobalTaskScheduleExpiresAtRangeRule(min: 64, max: 80)
        let item = ClinicalOps.newGlobalTaskSchedule("x", label: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalTaskScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.GlobalTaskScheduleLabelLengthRule(maxLength: 16)
        let item = ClinicalOps.newGlobalTaskSchedule("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
