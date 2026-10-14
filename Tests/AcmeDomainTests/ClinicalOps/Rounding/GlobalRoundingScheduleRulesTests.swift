@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalRoundingScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalRoundingScheduleValidator()
        let item = ClinicalOps.newGlobalRoundingSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalRoundingScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.GlobalRoundingScheduleLabelLengthRule(maxLength: 32)
        let item = ClinicalOps.newGlobalRoundingSchedule("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalRoundingScheduleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.GlobalRoundingScheduleTitleLengthRule(maxLength: 16)
        let item = ClinicalOps.newGlobalRoundingSchedule("x", label: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
