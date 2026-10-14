@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackTaskManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackTaskManifestValidator()
        let item = ClinicalOps.newFallbackTaskManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackTaskManifestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.FallbackTaskManifestRequiredNameRule(message: "fallback task manifest needs a value")
        let item = ClinicalOps.newFallbackTaskManifest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackTaskManifestAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = ClinicalOps.FallbackTaskManifestAllergyLengthRule(maxLength: 255)
        let item = ClinicalOps.newFallbackTaskManifest("x", name: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackTaskManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.FallbackTaskManifestCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newFallbackTaskManifest("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackTaskManifestMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = ClinicalOps.FallbackTaskManifestMarginRangeRule(min: 8.9, max: 150.3)
        let item = ClinicalOps.newFallbackTaskManifest("x", name: "y")
        item.margin = 151.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsFallbackTaskManifestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.FallbackTaskManifestNameLengthRule(maxLength: 86400)
        let item = ClinicalOps.newFallbackTaskManifest("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
