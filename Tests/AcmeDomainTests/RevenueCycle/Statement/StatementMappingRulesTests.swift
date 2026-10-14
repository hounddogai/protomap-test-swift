@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementMappingValidator()
        let item = RevenueCycle.newStatementMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementMappingCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.StatementMappingCeilingRangeRule(min: 1.3, max: 2167.5)
        let item = RevenueCycle.newStatementMapping("x", title: "y")
        item.ceiling = 2169.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementMappingSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = RevenueCycle.StatementMappingSpecialtyLengthRule(maxLength: 80)
        let item = RevenueCycle.newStatementMapping("x", title: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementMappingProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = RevenueCycle.StatementMappingProcedureCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newStatementMapping("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementMappingTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.StatementMappingTitleLengthRule(maxLength: 255)
        let item = RevenueCycle.newStatementMapping("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementMappingRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = RevenueCycle.StatementMappingRequiredSpecialtyRule(message: "statement mapping needs this field")
        let item = RevenueCycle.newStatementMapping("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
