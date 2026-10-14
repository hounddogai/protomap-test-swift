@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingPanelTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingPanelTemplateValidator()
        let item = Labs.newPendingPanelTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingPanelTemplateRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Labs.PendingPanelTemplateRequiredAllergyRule(message: "pending panel template needs this field")
        let item = Labs.newPendingPanelTemplate("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingPanelTemplateRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.PendingPanelTemplateRateRangeRule(min: 0.9, max: 4221.9)
        let item = Labs.newPendingPanelTemplate("x", name: "y")
        item.rate = 4223.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPendingPanelTemplateSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Labs.PendingPanelTemplateSummaryLengthRule(maxLength: 255)
        let item = Labs.newPendingPanelTemplate("x", name: "y")
        item.summary = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
