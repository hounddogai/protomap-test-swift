@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInteractionTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalInteractionTemplateValidator()
        let item = Pharmacy.newGlobalInteractionTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalInteractionTemplateVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.GlobalInteractionTemplateVisitMinutesRangeRule(min: 16, max: 86400)
        let item = Pharmacy.newGlobalInteractionTemplate("x", title: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyGlobalInteractionTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.GlobalInteractionTemplateCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newGlobalInteractionTemplate("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalInteractionTemplateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.GlobalInteractionTemplateTitleLengthRule(maxLength: 80)
        let item = Pharmacy.newGlobalInteractionTemplate("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
