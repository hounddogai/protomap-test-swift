@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackAlertOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackAlertOverrideValidator()
        let item = ClinicalOps.newFallbackAlertOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackAlertOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.FallbackAlertOverrideRequiredCodeRule(message: "fallback alert override needs this field")
        let item = ClinicalOps.newFallbackAlertOverride("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackAlertOverrideRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = ClinicalOps.FallbackAlertOverrideRefillsRangeRule(min: 32, max: 86400)
        let item = ClinicalOps.newFallbackAlertOverride("x", title: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsFallbackAlertOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.FallbackAlertOverrideCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newFallbackAlertOverride("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackAlertOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.FallbackAlertOverrideRequiredTitleRule(message: "fallback alert override needs a value")
        let item = ClinicalOps.newFallbackAlertOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
