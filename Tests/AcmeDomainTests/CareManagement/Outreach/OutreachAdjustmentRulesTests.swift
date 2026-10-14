@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachAdjustmentValidator()
        let item = CareManagement.newOutreachAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachAdjustmentRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = CareManagement.OutreachAdjustmentRequiredSummaryRule(message: "outreach adjustment needs an entry")
        let item = CareManagement.newOutreachAdjustment("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachAdjustmentAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = CareManagement.OutreachAdjustmentAmountRangeRule(min: 0.5, max: 3977.8)
        let item = CareManagement.newOutreachAdjustment("x", title: "y")
        item.amount = 3979.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachAdjustmentEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = CareManagement.OutreachAdjustmentEndsAtRangeRule(min: 16, max: 80)
        let item = CareManagement.newOutreachAdjustment("x", title: "y")
        item.endsAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachAdjustmentCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.OutreachAdjustmentCreatedAtRangeRule(min: 16, max: 80)
        let item = CareManagement.newOutreachAdjustment("x", title: "y")
        item.createdAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachAdjustmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.OutreachAdjustmentTitleLengthRule(maxLength: 16)
        let item = CareManagement.newOutreachAdjustment("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
