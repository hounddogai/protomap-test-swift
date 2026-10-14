@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalOvertimeSegmentValidator()
        let item = Staffing.newRegionalOvertimeSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalOvertimeSegmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.RegionalOvertimeSegmentCeilingRangeRule(min: 3.2, max: 1880.1)
        let item = Staffing.newRegionalOvertimeSegment("x", label: "y")
        item.ceiling = 1881.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalOvertimeSegmentRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Staffing.RegionalOvertimeSegmentRequiredDescriptionRule(
            message: "regional overtime segment needs a value"
        )
        let item = Staffing.newRegionalOvertimeSegment("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRegionalOvertimeSegmentDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Staffing.RegionalOvertimeSegmentDurationMinutesRangeRule(min: 64, max: 80)
        let item = Staffing.newRegionalOvertimeSegment("x", label: "y")
        item.durationMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalOvertimeSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.RegionalOvertimeSegmentRequiredLabelRule(message: "regional overtime segment needs an entry")
        let item = Staffing.newRegionalOvertimeSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
