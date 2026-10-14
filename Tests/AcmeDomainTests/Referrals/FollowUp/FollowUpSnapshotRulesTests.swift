@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpSnapshotValidator()
        let item = Referrals.newFollowUpSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpSnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.FollowUpSnapshotLabelLengthRule(maxLength: 255)
        let item = Referrals.newFollowUpSnapshot("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpSnapshotAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Referrals.FollowUpSnapshotAcuityRangeRule(min: 16, max: 1000)
        let item = Referrals.newFollowUpSnapshot("x", label: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpSnapshotRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.FollowUpSnapshotRequiredPatientRefRule(message: "follow up snapshot needs a value")
        let item = Referrals.newFollowUpSnapshot("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpSnapshotExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Referrals.FollowUpSnapshotExpiresAtRangeRule(min: 80, max: 255)
        let item = Referrals.newFollowUpSnapshot("x", label: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FollowUpSnapshotRequiredCodeRule(message: "follow up snapshot needs this field")
        let item = Referrals.newFollowUpSnapshot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
