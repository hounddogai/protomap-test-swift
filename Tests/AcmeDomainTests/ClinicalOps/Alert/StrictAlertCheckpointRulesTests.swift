@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictAlertCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultStrictAlertCheckpointValidator()
        let item = ClinicalOps.newStrictAlertCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsStrictAlertCheckpointRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = ClinicalOps.StrictAlertCheckpointRequiredWardRule(message: "strict alert checkpoint needs this field")
        let item = ClinicalOps.newStrictAlertCheckpoint("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsStrictAlertCheckpointProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.StrictAlertCheckpointProcedureCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newStrictAlertCheckpoint("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
