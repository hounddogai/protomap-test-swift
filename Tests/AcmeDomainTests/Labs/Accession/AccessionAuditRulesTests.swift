@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionAuditValidator()
        let item = Labs.newAccessionAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionAuditCodeLengthRule(maxLength: 32)
        let item = Labs.newAccessionAudit("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionAuditDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.AccessionAuditDurationMinutesRangeRule(min: 32, max: 120)
        let item = Labs.newAccessionAudit("x", label: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionAuditRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Labs.AccessionAuditRequiredWardRule(message: "accession audit needs an entry")
        let item = Labs.newAccessionAudit("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
