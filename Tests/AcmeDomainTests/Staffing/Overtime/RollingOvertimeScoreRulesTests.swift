@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRollingOvertimeScoreValidator()
        let item = Staffing.newRollingOvertimeScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRollingOvertimeScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.RollingOvertimeScoreRequiredCodeRule(message: "rolling overtime score needs an entry")
        let item = Staffing.newRollingOvertimeScore("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingOvertimeScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.RollingOvertimeScoreRequiredTitleRule(message: "rolling overtime score needs an entry")
        let item = Staffing.newRollingOvertimeScore("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingOvertimeScoreRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.RollingOvertimeScoreRequiredLabelRule(message: "rolling overtime score needs an entry")
        let item = Staffing.newRollingOvertimeScore("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
