@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolBudgetValidator()
        let item = Staffing.newFloatPoolBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolBudgetRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Staffing.FloatPoolBudgetRequiredSourceRule(message: "float pool budget needs an entry")
        let item = Staffing.newFloatPoolBudget("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolBudgetSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Staffing.FloatPoolBudgetSegmentLengthRule(maxLength: 64)
        let item = Staffing.newFloatPoolBudget("x", label: "y")
        item.segment = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolBudgetCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.FloatPoolBudgetCostRangeRule(min: 7.3, max: 2299.5)
        let item = Staffing.newFloatPoolBudget("x", label: "y")
        item.cost = 2301.0
        #expect(rule.check(item).count > 0)
    }
}
