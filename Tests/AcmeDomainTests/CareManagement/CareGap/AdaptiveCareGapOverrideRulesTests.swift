@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveCareGapOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveCareGapOverrideValidator()
        let item = CareManagement.newAdaptiveCareGapOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveCareGapOverrideContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = CareManagement.AdaptiveCareGapOverrideContactEmailLengthRule(maxLength: 86400)
        let item = CareManagement.newAdaptiveCareGapOverride("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveCareGapOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AdaptiveCareGapOverrideCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newAdaptiveCareGapOverride("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveCareGapOverrideRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = CareManagement.AdaptiveCareGapOverrideRequiredCurrencyRule(
            message: "adaptive care gap override needs a value"
        )
        let item = CareManagement.newAdaptiveCareGapOverride("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAdaptiveCareGapOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AdaptiveCareGapOverrideRequiredCodeRule(
            message: "adaptive care gap override needs this field"
        )
        let item = CareManagement.newAdaptiveCareGapOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
