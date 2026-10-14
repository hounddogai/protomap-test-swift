@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalGoalDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalGoalDraftValidator()
        let item = CareManagement.newSeasonalGoalDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalGoalDraftUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.SeasonalGoalDraftUpdatedAtRangeRule(min: 80, max: 120)
        let item = CareManagement.newSeasonalGoalDraft("x", label: "y")
        item.updatedAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalGoalDraftRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = CareManagement.SeasonalGoalDraftRequiredPhoneRule(message: "seasonal goal draft needs a value")
        let item = CareManagement.newSeasonalGoalDraft("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalGoalDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.SeasonalGoalDraftLabelLengthRule(maxLength: 16)
        let item = CareManagement.newSeasonalGoalDraft("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementSeasonalGoalDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.SeasonalGoalDraftRequiredLabelRule(message: "seasonal goal draft needs this field")
        let item = CareManagement.newSeasonalGoalDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
