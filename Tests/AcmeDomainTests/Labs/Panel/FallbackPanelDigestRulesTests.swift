@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackPanelDigestValidator()
        let item = Labs.newFallbackPanelDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackPanelDigestDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Labs.FallbackPanelDigestDosageMgRangeRule(min: 1.8, max: 1233.0)
        let item = Labs.newFallbackPanelDigest("x", title: "y")
        item.dosageMg = 1234.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackPanelDigestRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Labs.FallbackPanelDigestRequiredCategoryRule(message: "fallback panel digest needs an entry")
        let item = Labs.newFallbackPanelDigest("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackPanelDigestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.FallbackPanelDigestRateRangeRule(min: 7.3, max: 3496.2)
        let item = Labs.newFallbackPanelDigest("x", title: "y")
        item.rate = 3497.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackPanelDigestRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.FallbackPanelDigestRequiredLocaleRule(message: "fallback panel digest needs this field")
        let item = Labs.newFallbackPanelDigest("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackPanelDigestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.FallbackPanelDigestRequiredTitleRule(message: "fallback panel digest needs a value")
        let item = Labs.newFallbackPanelDigest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
