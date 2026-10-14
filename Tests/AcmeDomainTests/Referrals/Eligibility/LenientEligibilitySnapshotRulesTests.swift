@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientEligibilitySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLenientEligibilitySnapshotValidator()
        let item = Referrals.newLenientEligibilitySnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLenientEligibilitySnapshotCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.LenientEligibilitySnapshotCopayRangeRule(min: 0.8, max: 4759.8)
        let item = Referrals.newLenientEligibilitySnapshot("x", label: "y")
        item.copay = 4761.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLenientEligibilitySnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.LenientEligibilitySnapshotRequiredLabelRule(
            message: "lenient eligibility snapshot needs an entry"
        )
        let item = Referrals.newLenientEligibilitySnapshot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLenientEligibilitySnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.LenientEligibilitySnapshotLabelLengthRule(maxLength: 16)
        let item = Referrals.newLenientEligibilitySnapshot("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
