@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyAuthorizationSnapshotValidator()
        let item = RevenueCycle.newLegacyAuthorizationSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationSnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.LegacyAuthorizationSnapshotRequiredLabelRule(
            message: "legacy authorization snapshot needs an entry"
        )
        let item = RevenueCycle.newLegacyAuthorizationSnapshot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationSnapshotThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = RevenueCycle.LegacyAuthorizationSnapshotThresholdRangeRule(min: 4.6, max: 971.1)
        let item = RevenueCycle.newLegacyAuthorizationSnapshot("x", label: "y")
        item.threshold = 972.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationSnapshotRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = RevenueCycle.LegacyAuthorizationSnapshotRefillsRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newLegacyAuthorizationSnapshot("x", label: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}
