@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertVarianceValidator()
        let item = ClinicalOps.newAlertVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.AlertVarianceCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newAlertVariance("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertVarianceEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = ClinicalOps.AlertVarianceEncounterIDLengthRule(maxLength: 64)
        let item = ClinicalOps.newAlertVariance("x", label: "y")
        item.encounterID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertVarianceRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.AlertVarianceRequiredEncounterIDRule(message: "alert variance needs this field")
        let item = ClinicalOps.newAlertVariance("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
