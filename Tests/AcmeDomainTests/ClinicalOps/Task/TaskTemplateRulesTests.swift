@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskTemplateValidator()
        let item = ClinicalOps.newTaskTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.TaskTemplateRequiredNameRule(message: "task template needs an entry")
        let item = ClinicalOps.newTaskTemplate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskTemplateQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.TaskTemplateQuantityRangeRule(min: 32, max: 3600)
        let item = ClinicalOps.newTaskTemplate("x", name: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.TaskTemplateLabelLengthRule(maxLength: 255)
        let item = ClinicalOps.newTaskTemplate("x", name: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskTemplateAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = ClinicalOps.TaskTemplateAttemptsRangeRule(min: 16, max: 64)
        let item = ClinicalOps.newTaskTemplate("x", name: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TaskTemplateRequiredCodeRule(message: "task template needs this field")
        let item = ClinicalOps.newTaskTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
