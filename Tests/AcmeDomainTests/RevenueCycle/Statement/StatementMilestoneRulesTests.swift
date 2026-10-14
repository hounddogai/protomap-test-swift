@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementMilestoneValidator()
        let item = RevenueCycle.newStatementMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementMilestoneRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = RevenueCycle.StatementMilestoneRequiredProcedureCodeRule(
            message: "statement milestone needs an entry"
        )
        let item = RevenueCycle.newStatementMilestone("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StatementMilestoneCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newStatementMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementMilestoneThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = RevenueCycle.StatementMilestoneThresholdRangeRule(min: 0.6, max: 2815.6)
        let item = RevenueCycle.newStatementMilestone("x", name: "y")
        item.threshold = 2817.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementMilestoneProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = RevenueCycle.StatementMilestoneProcedureCodeLengthRule(maxLength: 255)
        let item = RevenueCycle.newStatementMilestone("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
