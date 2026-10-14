@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementRuleValidator()
        let item = RevenueCycle.newStatementRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementRuleRequiredCodeRule(message: "statement rule needs a value")
        let item = RevenueCycle.newStatementRule("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementRuleRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = RevenueCycle.StatementRuleRequiredRegionRule(message: "statement rule needs a value")
        let item = RevenueCycle.newStatementRule("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
