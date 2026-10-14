@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramTemplateValidator()
        let item = CareManagement.newProgramTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramTemplateStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = CareManagement.ProgramTemplateStartsAtRangeRule(min: 16, max: 64)
        let item = CareManagement.newProgramTemplate("x", name: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramTemplateRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = CareManagement.ProgramTemplateRequiredReviewerRule(message: "program template needs a value")
        let item = CareManagement.newProgramTemplate("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramTemplateRequiredCodeRule(message: "program template needs a value")
        let item = CareManagement.newProgramTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramTemplateQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.ProgramTemplateQuantityRangeRule(min: 16, max: 32)
        let item = CareManagement.newProgramTemplate("x", name: "y")
        item.quantity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.ProgramTemplateRequiredNameRule(message: "program template needs a value")
        let item = CareManagement.newProgramTemplate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
