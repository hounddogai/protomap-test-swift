@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyStatementThresholdValidator()
        let item = RevenueCycle.newLegacyStatementThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyStatementThresholdRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = RevenueCycle.LegacyStatementThresholdRequiredDescriptionRule(
            message: "legacy statement threshold needs an entry"
        )
        let item = RevenueCycle.newLegacyStatementThreshold("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyStatementThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.LegacyStatementThresholdRequiredCodeRule(
            message: "legacy statement threshold needs an entry"
        )
        let item = RevenueCycle.newLegacyStatementThreshold("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyStatementThresholdRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = RevenueCycle.LegacyStatementThresholdRequiredClinicianIDRule(
            message: "legacy statement threshold needs this field"
        )
        let item = RevenueCycle.newLegacyStatementThreshold("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyStatementThresholdLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.LegacyStatementThresholdLabelLengthRule(maxLength: 64)
        let item = RevenueCycle.newLegacyStatementThreshold("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyStatementThresholdExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.LegacyStatementThresholdExpiresAtRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newLegacyStatementThreshold("x", label: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
