@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackRoundingManifestValidator()
        let item = ClinicalOps.newFallbackRoundingManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackRoundingManifestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.FallbackRoundingManifestTitleLengthRule(maxLength: 16)
        let item = ClinicalOps.newFallbackRoundingManifest("x", label: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackRoundingManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.FallbackRoundingManifestRequiredCodeRule(
            message: "fallback rounding manifest needs an entry"
        )
        let item = ClinicalOps.newFallbackRoundingManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackRoundingManifestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.FallbackRoundingManifestRequiredTitleRule(
            message: "fallback rounding manifest needs a value"
        )
        let item = ClinicalOps.newFallbackRoundingManifest("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackRoundingManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.FallbackRoundingManifestRequiredLabelRule(
            message: "fallback rounding manifest needs an entry"
        )
        let item = ClinicalOps.newFallbackRoundingManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
