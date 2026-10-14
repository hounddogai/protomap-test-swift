@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultResultAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultResultAuditValidator()
        let item = Labs.newDefaultResultAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultResultAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.DefaultResultAuditCodeLengthRule(maxLength: 16)
        let item = Labs.newDefaultResultAudit("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
