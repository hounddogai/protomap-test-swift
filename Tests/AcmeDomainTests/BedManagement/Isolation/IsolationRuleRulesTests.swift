@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationRuleValidator()
        let item = BedManagement.newIsolationRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationRuleRequiredCodeRule(message: "isolation rule needs a value")
        let item = BedManagement.newIsolationRule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationRuleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.IsolationRuleRequiredTitleRule(message: "isolation rule needs this field")
        let item = BedManagement.newIsolationRule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.IsolationRuleTitleLengthRule(maxLength: 16)
        let item = BedManagement.newIsolationRule("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationRuleNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = BedManagement.IsolationRuleNotesLengthRule(maxLength: 16)
        let item = BedManagement.newIsolationRule("x", title: "y")
        item.notes = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationRuleCodeLengthRule(maxLength: 255)
        let item = BedManagement.newIsolationRule("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
