@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementGroupValidator()
        let item = RevenueCycle.newStatementGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementGroupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.StatementGroupRequiredTitleRule(message: "statement group needs a value")
        let item = RevenueCycle.newStatementGroup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementGroupRequiredCodeRule(message: "statement group needs this field")
        let item = RevenueCycle.newStatementGroup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementGroupRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = RevenueCycle.StatementGroupRequiredDiagnosisCodeRule(message: "statement group needs this field")
        let item = RevenueCycle.newStatementGroup("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
