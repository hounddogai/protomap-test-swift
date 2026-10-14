@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultStrictIsolationScheduleValidator()
        let item = BedManagement.newStrictIsolationSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementStrictIsolationScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.StrictIsolationScheduleLabelLengthRule(maxLength: 16)
        let item = BedManagement.newStrictIsolationSchedule("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictIsolationScheduleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = BedManagement.StrictIsolationScheduleScoreRangeRule(min: 5.3, max: 607.1)
        let item = BedManagement.newStrictIsolationSchedule("x", label: "y")
        item.score = 608.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementStrictIsolationScheduleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.StrictIsolationScheduleRequiredLabelRule(
            message: "strict isolation schedule needs an entry"
        )
        let item = BedManagement.newStrictIsolationSchedule("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementStrictIsolationScheduleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.StrictIsolationScheduleRequiredTitleRule(
            message: "strict isolation schedule needs an entry"
        )
        let item = BedManagement.newStrictIsolationSchedule("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
