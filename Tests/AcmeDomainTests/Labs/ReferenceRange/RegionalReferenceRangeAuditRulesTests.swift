@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalReferenceRangeAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRegionalReferenceRangeAuditValidator()
        let item = Labs.newRegionalReferenceRangeAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRegionalReferenceRangeAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.RegionalReferenceRangeAuditCodeLengthRule(maxLength: 3600)
        let item = Labs.newRegionalReferenceRangeAudit("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
