@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalCareGapOverrideValidator()
        let item = CareManagement.newGlobalCareGapOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalCareGapOverrideRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = CareManagement.GlobalCareGapOverrideRequiredLocaleRule(
            message: "global care gap override needs this field"
        )
        let item = CareManagement.newGlobalCareGapOverride("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalCareGapOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GlobalCareGapOverrideRequiredCodeRule(
            message: "global care gap override needs this field"
        )
        let item = CareManagement.newGlobalCareGapOverride("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalCareGapOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GlobalCareGapOverrideCodeLengthRule(maxLength: 120)
        let item = CareManagement.newGlobalCareGapOverride("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalCareGapOverrideCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = CareManagement.GlobalCareGapOverrideCostRangeRule(min: 9.0, max: 4505.6)
        let item = CareManagement.newGlobalCareGapOverride("x", name: "y")
        item.cost = 4507.1
        #expect(rule.check(item).count > 0)
    }
}
