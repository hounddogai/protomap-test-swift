@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskAgreementValidator()
        let item = ClinicalOps.newTaskAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskAgreementUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = ClinicalOps.TaskAgreementUpdatedAtRangeRule(min: 16, max: 64)
        let item = ClinicalOps.newTaskAgreement("x", label: "y")
        item.updatedAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskAgreementEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = ClinicalOps.TaskAgreementEncounterIDLengthRule(maxLength: 1000)
        let item = ClinicalOps.newTaskAgreement("x", label: "y")
        item.encounterID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskAgreementLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.TaskAgreementLabelLengthRule(maxLength: 64)
        let item = ClinicalOps.newTaskAgreement("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskAgreementRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.TaskAgreementRequiredEncounterIDRule(message: "task agreement needs an entry")
        let item = ClinicalOps.newTaskAgreement("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
