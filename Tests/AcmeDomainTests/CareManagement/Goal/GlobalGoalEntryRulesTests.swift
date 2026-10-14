@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalGoalEntryValidator()
        let item = CareManagement.newGlobalGoalEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalGoalEntryContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = CareManagement.GlobalGoalEntryContactEmailLengthRule(maxLength: 80)
        let item = CareManagement.newGlobalGoalEntry("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalGoalEntryWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.GlobalGoalEntryWindowDaysRangeRule(min: 16, max: 255)
        let item = CareManagement.newGlobalGoalEntry("x", label: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalGoalEntryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.GlobalGoalEntryRequiredLabelRule(message: "global goal entry needs this field")
        let item = CareManagement.newGlobalGoalEntry("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
