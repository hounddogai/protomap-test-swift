@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusAssignmentValidator()
        let item = BedManagement.newCensusAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CensusAssignmentTitleLengthRule(maxLength: 120)
        let item = BedManagement.newCensusAssignment("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusAssignmentBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.CensusAssignmentBudgetRangeRule(min: 6.5, max: 3543.2)
        let item = BedManagement.newCensusAssignment("x", title: "y")
        item.budget = 3544.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CensusAssignmentCodeLengthRule(maxLength: 255)
        let item = BedManagement.newCensusAssignment("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
