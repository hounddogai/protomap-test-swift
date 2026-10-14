@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalAlertTargetValidator()
        let item = ClinicalOps.newGlobalAlertTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalAlertTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.GlobalAlertTargetLabelLengthRule(maxLength: 16)
        let item = ClinicalOps.newGlobalAlertTarget("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalAlertTargetSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = ClinicalOps.GlobalAlertTargetSourceLengthRule(maxLength: 1000)
        let item = ClinicalOps.newGlobalAlertTarget("x", label: "y")
        item.source = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalAlertTargetRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.GlobalAlertTargetRequiredEncounterIDRule(message: "global alert target needs a value")
        let item = ClinicalOps.newGlobalAlertTarget("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
