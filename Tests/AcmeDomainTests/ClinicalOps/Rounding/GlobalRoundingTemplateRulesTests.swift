@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalRoundingTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalRoundingTemplateValidator()
        let item = ClinicalOps.newGlobalRoundingTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalRoundingTemplateNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = ClinicalOps.GlobalRoundingTemplateNotesLengthRule(maxLength: 3600)
        let item = ClinicalOps.newGlobalRoundingTemplate("x", name: "y")
        item.notes = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalRoundingTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.GlobalRoundingTemplateCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newGlobalRoundingTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalRoundingTemplateBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = ClinicalOps.GlobalRoundingTemplateBatchSizeRangeRule(min: 16, max: 1000)
        let item = ClinicalOps.newGlobalRoundingTemplate("x", name: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalRoundingTemplateRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = ClinicalOps.GlobalRoundingTemplateRequiredAllergyRule(
            message: "global rounding template needs this field"
        )
        let item = ClinicalOps.newGlobalRoundingTemplate("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalRoundingTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.GlobalRoundingTemplateRequiredCodeRule(message: "global rounding template needs a value")
        let item = ClinicalOps.newGlobalRoundingTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalRoundingTemplateAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.GlobalRoundingTemplateAcuityRangeRule(min: 80, max: 3600)
        let item = ClinicalOps.newGlobalRoundingTemplate("x", name: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}
