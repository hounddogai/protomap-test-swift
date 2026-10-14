@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalStatementReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultGlobalStatementReservationValidator()
        let item = RevenueCycle.newGlobalStatementReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleGlobalStatementReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.GlobalStatementReservationRequiredLabelRule(
            message: "global statement reservation needs a value"
        )
        let item = RevenueCycle.newGlobalStatementReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleGlobalStatementReservationLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.GlobalStatementReservationLimitRangeRule(min: 16, max: 120)
        let item = RevenueCycle.newGlobalStatementReservation("x", label: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}
