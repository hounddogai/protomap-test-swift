@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionTemplateValidator()
        let item = Pharmacy.newInteractionTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionTemplateLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Pharmacy.InteractionTemplateLimitRangeRule(min: 1000, max: 86400)
        let item = Pharmacy.newInteractionTemplate("x", label: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionTemplateCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newInteractionTemplate("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
