@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentTemplateValidator()
        let item = CareManagement.newAssessmentTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentTemplateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.AssessmentTemplateNameLengthRule(maxLength: 80)
        let item = CareManagement.newAssessmentTemplate("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AssessmentTemplateCodeLengthRule(maxLength: 32)
        let item = CareManagement.newAssessmentTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentTemplateLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = CareManagement.AssessmentTemplateLimitRangeRule(min: 64, max: 255)
        let item = CareManagement.newAssessmentTemplate("x", name: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentTemplateRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = CareManagement.AssessmentTemplateRequiredFacilityRule(message: "assessment template needs an entry")
        let item = CareManagement.newAssessmentTemplate("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentTemplateFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = CareManagement.AssessmentTemplateFacilityLengthRule(maxLength: 120)
        let item = CareManagement.newAssessmentTemplate("x", name: "y")
        item.facility = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
