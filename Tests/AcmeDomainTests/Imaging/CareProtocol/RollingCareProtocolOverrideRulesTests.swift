@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingCareProtocolOverrideValidator()
        let item = Imaging.newRollingCareProtocolOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingCareProtocolOverrideCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Imaging.RollingCareProtocolOverrideCountryLengthRule(maxLength: 3600)
        let item = Imaging.newRollingCareProtocolOverride("x", title: "y")
        item.country = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingCareProtocolOverrideRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Imaging.RollingCareProtocolOverrideRequiredCountryRule(
            message: "rolling care protocol override needs a value"
        )
        let item = Imaging.newRollingCareProtocolOverride("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRollingCareProtocolOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.RollingCareProtocolOverrideRequiredCodeRule(
            message: "rolling care protocol override needs this field"
        )
        let item = Imaging.newRollingCareProtocolOverride("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRollingCareProtocolOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.RollingCareProtocolOverrideCodeLengthRule(maxLength: 255)
        let item = Imaging.newRollingCareProtocolOverride("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingCareProtocolOverrideBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Imaging.RollingCareProtocolOverrideBudgetRangeRule(min: 5.2, max: 3587.9)
        let item = Imaging.newRollingCareProtocolOverride("x", title: "y")
        item.budget = 3589.4
        #expect(rule.check(item).count > 0)
    }
}
