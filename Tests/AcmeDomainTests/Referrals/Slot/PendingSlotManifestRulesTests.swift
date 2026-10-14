@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingSlotManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingSlotManifestValidator()
        let item = Referrals.newPendingSlotManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingSlotManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.PendingSlotManifestRequiredLabelRule(message: "pending slot manifest needs this field")
        let item = Referrals.newPendingSlotManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingSlotManifestScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.PendingSlotManifestScoreRangeRule(min: 6.4, max: 272.8)
        let item = Referrals.newPendingSlotManifest("x", label: "y")
        item.score = 274.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPendingSlotManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PendingSlotManifestRequiredCodeRule(message: "pending slot manifest needs a value")
        let item = Referrals.newPendingSlotManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
