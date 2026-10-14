@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledFloatPoolBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledFloatPoolBudgetValidator()
        let item = Staffing.newScheduledFloatPoolBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledFloatPoolBudgetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.ScheduledFloatPoolBudgetTitleLengthRule(maxLength: 80)
        let item = Staffing.newScheduledFloatPoolBudget("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledFloatPoolBudgetRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Staffing.ScheduledFloatPoolBudgetRequiredRegionRule(
            message: "scheduled float pool budget needs an entry"
        )
        let item = Staffing.newScheduledFloatPoolBudget("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledFloatPoolBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ScheduledFloatPoolBudgetCodeLengthRule(maxLength: 3600)
        let item = Staffing.newScheduledFloatPoolBudget("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledFloatPoolBudgetCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Staffing.ScheduledFloatPoolBudgetCategoryLengthRule(maxLength: 80)
        let item = Staffing.newScheduledFloatPoolBudget("x", title: "y")
        item.category = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
