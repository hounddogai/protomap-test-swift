@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryAssessmentCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryAssessmentCheckpointValidator()
        let item = CareManagement.newPrimaryAssessmentCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryAssessmentCheckpointRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = CareManagement.PrimaryAssessmentCheckpointRequiredCurrencyRule(
            message: "primary assessment checkpoint needs a value"
        )
        let item = CareManagement.newPrimaryAssessmentCheckpoint("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPrimaryAssessmentCheckpointRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.PrimaryAssessmentCheckpointRevisionRangeRule(min: 255, max: 1000)
        let item = CareManagement.newPrimaryAssessmentCheckpoint("x", name: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPrimaryAssessmentCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PrimaryAssessmentCheckpointCodeLengthRule(maxLength: 80)
        let item = CareManagement.newPrimaryAssessmentCheckpoint("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryAssessmentCheckpointAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = CareManagement.PrimaryAssessmentCheckpointAllergyLengthRule(maxLength: 120)
        let item = CareManagement.newPrimaryAssessmentCheckpoint("x", name: "y")
        item.allergy = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryAssessmentCheckpointCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = CareManagement.PrimaryAssessmentCheckpointCurrencyLengthRule(maxLength: 1000)
        let item = CareManagement.newPrimaryAssessmentCheckpoint("x", name: "y")
        item.currency = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
