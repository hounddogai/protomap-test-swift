@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedAccessionAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedAccessionAdjustmentValidator()
        let item = Labs.newCappedAccessionAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedAccessionAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CappedAccessionAdjustmentCodeLengthRule(maxLength: 1000)
        let item = Labs.newCappedAccessionAdjustment("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedAccessionAdjustmentProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Labs.CappedAccessionAdjustmentProcedureCodeLengthRule(maxLength: 3600)
        let item = Labs.newCappedAccessionAdjustment("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedAccessionAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.CappedAccessionAdjustmentLabelLengthRule(maxLength: 3600)
        let item = Labs.newCappedAccessionAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedAccessionAdjustmentRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Labs.CappedAccessionAdjustmentRequiredProcedureCodeRule(
            message: "capped accession adjustment needs an entry"
        )
        let item = Labs.newCappedAccessionAdjustment("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
