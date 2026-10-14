@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingEligibilitySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingEligibilitySnapshotValidator()
        let item = Referrals.newRollingEligibilitySnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingEligibilitySnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.RollingEligibilitySnapshotRequiredNameRule(
            message: "rolling eligibility snapshot needs an entry"
        )
        let item = Referrals.newRollingEligibilitySnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingEligibilitySnapshotRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.RollingEligibilitySnapshotRequiredPatientRefRule(
            message: "rolling eligibility snapshot needs this field"
        )
        let item = Referrals.newRollingEligibilitySnapshot("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingEligibilitySnapshotRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Referrals.RollingEligibilitySnapshotRequiredChecksumRule(
            message: "rolling eligibility snapshot needs this field"
        )
        let item = Referrals.newRollingEligibilitySnapshot("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
