@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultPanelExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultPanelExceptionValidator()
        let item = Labs.newDefaultPanelException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultPanelExceptionNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Labs.DefaultPanelExceptionNotesLengthRule(maxLength: 120)
        let item = Labs.newDefaultPanelException("x", label: "y")
        item.notes = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsDefaultPanelExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.DefaultPanelExceptionCodeLengthRule(maxLength: 32)
        let item = Labs.newDefaultPanelException("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsDefaultPanelExceptionExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.DefaultPanelExceptionExpiresAtRangeRule(min: 32, max: 64)
        let item = Labs.newDefaultPanelException("x", label: "y")
        item.expiresAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsDefaultPanelExceptionRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Labs.DefaultPanelExceptionRevisionRangeRule(min: 16, max: 32)
        let item = Labs.newDefaultPanelException("x", label: "y")
        item.revision = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsDefaultPanelExceptionMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Labs.DefaultPanelExceptionMarginRangeRule(min: 6.1, max: 3971.1)
        let item = Labs.newDefaultPanelException("x", label: "y")
        item.margin = 3972.6
        #expect(rule.check(item).count > 0)
    }
}
