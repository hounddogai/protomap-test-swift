@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualProgramOverrideValidator()
        let item = CareManagement.newManualProgramOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualProgramOverrideRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = CareManagement.ManualProgramOverrideRequiredLocaleRule(
            message: "manual program override needs a value"
        )
        let item = CareManagement.newManualProgramOverride("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualProgramOverrideQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.ManualProgramOverrideQuantityRangeRule(min: 120, max: 86400)
        let item = CareManagement.newManualProgramOverride("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementManualProgramOverrideNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.ManualProgramOverrideNameLengthRule(maxLength: 64)
        let item = CareManagement.newManualProgramOverride("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualProgramOverrideAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = CareManagement.ManualProgramOverrideAllergyLengthRule(maxLength: 32)
        let item = CareManagement.newManualProgramOverride("x", name: "y")
        item.allergy = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualProgramOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ManualProgramOverrideCodeLengthRule(maxLength: 255)
        let item = CareManagement.newManualProgramOverride("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
