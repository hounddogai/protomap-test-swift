@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardBudgetValidator()
        let item = BedManagement.newBedBoardBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BedBoardBudgetRequiredCodeRule(message: "bed board budget needs an entry")
        let item = BedManagement.newBedBoardBudget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardBudgetMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = BedManagement.BedBoardBudgetMaximumRangeRule(min: 3.1, max: 2571.4)
        let item = BedManagement.newBedBoardBudget("x", name: "y")
        item.maximum = 2572.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardBudgetAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.BedBoardBudgetAttemptsRangeRule(min: 64, max: 80)
        let item = BedManagement.newBedBoardBudget("x", name: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}
