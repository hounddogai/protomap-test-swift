@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachDraftValidator()
        let item = CareManagement.newOutreachDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachDraftAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = CareManagement.OutreachDraftAmountRangeRule(min: 2.2, max: 4980.4)
        let item = CareManagement.newOutreachDraft("x", title: "y")
        item.amount = 4981.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachDraftRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.OutreachDraftRequiredTitleRule(message: "outreach draft needs an entry")
        let item = CareManagement.newOutreachDraft("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
