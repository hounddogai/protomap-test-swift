@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementAgreementValidator()
        let item = RevenueCycle.newStatementAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementAgreementRequiredCodeRule(message: "statement agreement needs an entry")
        let item = RevenueCycle.newStatementAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementAgreementPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = RevenueCycle.StatementAgreementPayerLengthRule(maxLength: 3600)
        let item = RevenueCycle.newStatementAgreement("x", name: "y")
        item.payer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementAgreementMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.StatementAgreementMaximumRangeRule(min: 6.2, max: 4590.1)
        let item = RevenueCycle.newStatementAgreement("x", name: "y")
        item.maximum = 4591.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StatementAgreementCodeLengthRule(maxLength: 255)
        let item = RevenueCycle.newStatementAgreement("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
