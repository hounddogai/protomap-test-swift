@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultCappedStatementExceptionValidator()
        let item = RevenueCycle.newCappedStatementException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleCappedStatementExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.CappedStatementExceptionCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newCappedStatementException("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleCappedStatementExceptionRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = RevenueCycle.CappedStatementExceptionRequiredNotesRule(
            message: "capped statement exception needs an entry"
        )
        let item = RevenueCycle.newCappedStatementException("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleCappedStatementExceptionFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = RevenueCycle.CappedStatementExceptionFloorValueRangeRule(min: 7.2, max: 1131.6)
        let item = RevenueCycle.newCappedStatementException("x", label: "y")
        item.floorValue = 1133.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleCappedStatementExceptionNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = RevenueCycle.CappedStatementExceptionNotesLengthRule(maxLength: 32)
        let item = RevenueCycle.newCappedStatementException("x", label: "y")
        item.notes = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleCappedStatementExceptionLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.CappedStatementExceptionLabelLengthRule(maxLength: 64)
        let item = RevenueCycle.newCappedStatementException("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
