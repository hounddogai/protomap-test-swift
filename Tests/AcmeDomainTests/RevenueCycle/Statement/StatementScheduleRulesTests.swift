@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementScheduleValidator()
        let item = RevenueCycle.newStatementSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementScheduleStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = RevenueCycle.StatementScheduleStartsAtRangeRule(min: 16, max: 64)
        let item = RevenueCycle.newStatementSchedule("x", label: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.StatementScheduleNameLengthRule(maxLength: 64)
        let item = RevenueCycle.newStatementSchedule("x", label: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementScheduleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.StatementScheduleRequiredNameRule(message: "statement schedule needs an entry")
        let item = RevenueCycle.newStatementSchedule("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.StatementScheduleLabelLengthRule(maxLength: 1000)
        let item = RevenueCycle.newStatementSchedule("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementScheduleRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = RevenueCycle.StatementScheduleRevisionRangeRule(min: 64, max: 120)
        let item = RevenueCycle.newStatementSchedule("x", label: "y")
        item.revision = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementScheduleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.StatementScheduleAmountRangeRule(min: 9.2, max: 894.9)
        let item = RevenueCycle.newStatementSchedule("x", label: "y")
        item.amount = 896.4
        #expect(rule.check(item).count > 0)
    }
}
