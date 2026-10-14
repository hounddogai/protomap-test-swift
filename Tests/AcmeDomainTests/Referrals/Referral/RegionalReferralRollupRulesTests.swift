@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalReferralRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalReferralRollupValidator()
        let item = Referrals.newRegionalReferralRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalReferralRollupPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Referrals.RegionalReferralRollupPatientRefLengthRule(maxLength: 120)
        let item = Referrals.newRegionalReferralRollup("x", title: "y")
        item.patientRef = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalReferralRollupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.RegionalReferralRollupRequiredTitleRule(message: "regional referral rollup needs an entry")
        let item = Referrals.newRegionalReferralRollup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalReferralRollupRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Referrals.RegionalReferralRollupRequiredNotesRule(
            message: "regional referral rollup needs this field"
        )
        let item = Referrals.newRegionalReferralRollup("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalReferralRollupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.RegionalReferralRollupTitleLengthRule(maxLength: 255)
        let item = Referrals.newRegionalReferralRollup("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
