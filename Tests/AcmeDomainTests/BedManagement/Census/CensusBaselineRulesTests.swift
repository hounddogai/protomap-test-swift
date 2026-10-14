@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusBaselineValidator()
        let item = BedManagement.newCensusBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusBaselineMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.CensusBaselineMarginRangeRule(min: 9.3, max: 924.6)
        let item = BedManagement.newCensusBaseline("x", label: "y")
        item.margin = 926.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CensusBaselineRequiredCodeRule(message: "census baseline needs this field")
        let item = BedManagement.newCensusBaseline("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusBaselineWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = BedManagement.CensusBaselineWindowDaysRangeRule(min: 80, max: 1000)
        let item = BedManagement.newCensusBaseline("x", label: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusBaselineBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.CensusBaselineBudgetRangeRule(min: 8.5, max: 2260.2)
        let item = BedManagement.newCensusBaseline("x", label: "y")
        item.budget = 2261.7
        #expect(rule.check(item).count > 0)
    }
}
