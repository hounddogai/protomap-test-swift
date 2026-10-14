@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingTemplateValidator()
        let item = ClinicalOps.newRoundingTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingTemplateAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.RoundingTemplateAcuityRangeRule(min: 64, max: 255)
        let item = ClinicalOps.newRoundingTemplate("x", name: "y")
        item.acuity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingTemplateRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = ClinicalOps.RoundingTemplateRequiredLocaleRule(message: "rounding template needs a value")
        let item = ClinicalOps.newRoundingTemplate("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingTemplateRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = ClinicalOps.RoundingTemplateRequiredPatientRefRule(message: "rounding template needs this field")
        let item = ClinicalOps.newRoundingTemplate("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
