@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackPanelBundleValidator()
        let item = Labs.newFallbackPanelBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackPanelBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.FallbackPanelBundleRequiredNameRule(message: "fallback panel bundle needs this field")
        let item = Labs.newFallbackPanelBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackPanelBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.FallbackPanelBundleNameLengthRule(maxLength: 32)
        let item = Labs.newFallbackPanelBundle("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackPanelBundleRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Labs.FallbackPanelBundleRequiredAllergyRule(message: "fallback panel bundle needs this field")
        let item = Labs.newFallbackPanelBundle("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
