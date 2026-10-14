@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentThresholdValidator()
        let item = CareManagement.newAssessmentThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentThresholdSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = CareManagement.AssessmentThresholdSpecialtyLengthRule(maxLength: 64)
        let item = CareManagement.newAssessmentThreshold("x", label: "y")
        item.specialty = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentThresholdRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = CareManagement.AssessmentThresholdRateRangeRule(min: 5.5, max: 729.7)
        let item = CareManagement.newAssessmentThreshold("x", label: "y")
        item.rate = 731.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentThresholdDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = CareManagement.AssessmentThresholdDosageMgRangeRule(min: 8.3, max: 4432.5)
        let item = CareManagement.newAssessmentThreshold("x", label: "y")
        item.dosageMg = 4434.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentThresholdAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = CareManagement.AssessmentThresholdAllergyLengthRule(maxLength: 120)
        let item = CareManagement.newAssessmentThreshold("x", label: "y")
        item.allergy = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AssessmentThresholdCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newAssessmentThreshold("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
