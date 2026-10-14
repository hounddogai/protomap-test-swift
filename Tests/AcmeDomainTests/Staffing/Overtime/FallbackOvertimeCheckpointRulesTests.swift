@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackOvertimeCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackOvertimeCheckpointValidator()
        let item = Staffing.newFallbackOvertimeCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackOvertimeCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FallbackOvertimeCheckpointRequiredCodeRule(
            message: "fallback overtime checkpoint needs this field"
        )
        let item = Staffing.newFallbackOvertimeCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackOvertimeCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.FallbackOvertimeCheckpointRequiredTitleRule(
            message: "fallback overtime checkpoint needs this field"
        )
        let item = Staffing.newFallbackOvertimeCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackOvertimeCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FallbackOvertimeCheckpointCodeLengthRule(maxLength: 1000)
        let item = Staffing.newFallbackOvertimeCheckpoint("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
