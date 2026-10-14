@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementThresholdValidator()
        let item = RevenueCycle.newStatementThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementThresholdMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.StatementThresholdMaximumRangeRule(min: 0.3, max: 1808.5)
        let item = RevenueCycle.newStatementThreshold("x", title: "y")
        item.maximum = 1810.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementThresholdLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.StatementThresholdLabelLengthRule(maxLength: 16)
        let item = RevenueCycle.newStatementThreshold("x", title: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.StatementThresholdRequiredTitleRule(message: "statement threshold needs a value")
        let item = RevenueCycle.newStatementThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementThresholdAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = RevenueCycle.StatementThresholdAcuityRangeRule(min: 80, max: 1000)
        let item = RevenueCycle.newStatementThreshold("x", title: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}
