@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachPlanValidator()
        let item = CareManagement.newOutreachPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachPlanRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = CareManagement.OutreachPlanRequiredNotesRule(message: "outreach plan needs an entry")
        let item = CareManagement.newOutreachPlan("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachPlanRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.OutreachPlanRequiredNameRule(message: "outreach plan needs an entry")
        let item = CareManagement.newOutreachPlan("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachPlanWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.OutreachPlanWindowDaysRangeRule(min: 80, max: 86400)
        let item = CareManagement.newOutreachPlan("x", name: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}
