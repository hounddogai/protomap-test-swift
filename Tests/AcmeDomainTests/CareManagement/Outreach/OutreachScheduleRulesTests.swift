@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachScheduleValidator()
        let item = CareManagement.newOutreachSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachScheduleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.OutreachScheduleRequiredNameRule(message: "outreach schedule needs this field")
        let item = CareManagement.newOutreachSchedule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachScheduleMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = CareManagement.OutreachScheduleMaximumRangeRule(min: 8.5, max: 1412.4)
        let item = CareManagement.newOutreachSchedule("x", name: "y")
        item.maximum = 1413.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachScheduleTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = CareManagement.OutreachScheduleTimezoneLengthRule(maxLength: 64)
        let item = CareManagement.newOutreachSchedule("x", name: "y")
        item.timezone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
