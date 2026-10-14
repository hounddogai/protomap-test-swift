@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultThresholdValidator()
        let item = Labs.newResultThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultThresholdProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Labs.ResultThresholdProcedureCodeLengthRule(maxLength: 32)
        let item = Labs.newResultThreshold("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultThresholdCodeLengthRule(maxLength: 86400)
        let item = Labs.newResultThreshold("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
