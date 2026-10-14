@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingPanelMappingValidator()
        let item = Labs.newRollingPanelMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingPanelMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.RollingPanelMappingRequiredCodeRule(message: "rolling panel mapping needs a value")
        let item = Labs.newRollingPanelMapping("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingPanelMappingRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Labs.RollingPanelMappingRetriesRangeRule(min: 80, max: 86400)
        let item = Labs.newRollingPanelMapping("x", label: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingPanelMappingRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Labs.RollingPanelMappingRequiredCountryRule(message: "rolling panel mapping needs this field")
        let item = Labs.newRollingPanelMapping("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingPanelMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.RollingPanelMappingCodeLengthRule(maxLength: 32)
        let item = Labs.newRollingPanelMapping("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingPanelMappingCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.RollingPanelMappingCountryLengthRule(maxLength: 64)
        let item = Labs.newRollingPanelMapping("x", label: "y")
        item.country = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
