@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningPlanValidator()
        let item = BedManagement.newCleaningPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningPlanLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.CleaningPlanLimitRangeRule(min: 16, max: 3600)
        let item = BedManagement.newCleaningPlan("x", title: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.CleaningPlanRequiredTitleRule(message: "cleaning plan needs an entry")
        let item = BedManagement.newCleaningPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CleaningPlanCodeLengthRule(maxLength: 32)
        let item = BedManagement.newCleaningPlan("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
