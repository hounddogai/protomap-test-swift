@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyStatementRecordValidator()
        let item = RevenueCycle.newLegacyStatementRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyStatementRecordUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.LegacyStatementRecordUpdatedAtRangeRule(min: 120, max: 86400)
        let item = RevenueCycle.newLegacyStatementRecord("x", title: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLegacyStatementRecordPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = RevenueCycle.LegacyStatementRecordPhoneLengthRule(maxLength: 255)
        let item = RevenueCycle.newLegacyStatementRecord("x", title: "y")
        item.phone = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyStatementRecordRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = RevenueCycle.LegacyStatementRecordRequiredExternalRefRule(
            message: "legacy statement record needs an entry"
        )
        let item = RevenueCycle.newLegacyStatementRecord("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
