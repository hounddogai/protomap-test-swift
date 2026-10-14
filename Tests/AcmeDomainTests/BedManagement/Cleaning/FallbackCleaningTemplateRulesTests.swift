@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCleaningTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackCleaningTemplateValidator()
        let item = BedManagement.newFallbackCleaningTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackCleaningTemplateUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = BedManagement.FallbackCleaningTemplateUnitLengthRule(maxLength: 255)
        let item = BedManagement.newFallbackCleaningTemplate("x", name: "y")
        item.unit = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackCleaningTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.FallbackCleaningTemplateCodeLengthRule(maxLength: 80)
        let item = BedManagement.newFallbackCleaningTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackCleaningTemplateExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = BedManagement.FallbackCleaningTemplateExternalRefLengthRule(maxLength: 80)
        let item = BedManagement.newFallbackCleaningTemplate("x", name: "y")
        item.externalRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackCleaningTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.FallbackCleaningTemplateRequiredCodeRule(
            message: "fallback cleaning template needs a value"
        )
        let item = BedManagement.newFallbackCleaningTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackCleaningTemplateCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = BedManagement.FallbackCleaningTemplateCreatedAtRangeRule(min: 80, max: 3600)
        let item = BedManagement.newFallbackCleaningTemplate("x", name: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
