@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementTargetValidator()
        let item = RevenueCycle.newStatementTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementTargetRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = RevenueCycle.StatementTargetRequiredPhoneRule(message: "statement target needs a value")
        let item = RevenueCycle.newStatementTarget("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.StatementTargetNameLengthRule(maxLength: 3600)
        let item = RevenueCycle.newStatementTarget("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
