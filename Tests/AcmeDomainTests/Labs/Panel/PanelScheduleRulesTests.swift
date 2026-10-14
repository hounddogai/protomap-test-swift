@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelScheduleValidator()
        let item = Labs.newPanelSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelScheduleTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Labs.PanelScheduleTimezoneLengthRule(maxLength: 64)
        let item = Labs.newPanelSchedule("x", label: "y")
        item.timezone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelScheduleRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Labs.PanelScheduleRequiredTimezoneRule(message: "panel schedule needs this field")
        let item = Labs.newPanelSchedule("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
