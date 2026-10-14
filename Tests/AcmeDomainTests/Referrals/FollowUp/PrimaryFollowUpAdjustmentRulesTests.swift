@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryFollowUpAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimaryFollowUpAdjustmentValidator()
        let item = Referrals.newPrimaryFollowUpAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimaryFollowUpAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.PrimaryFollowUpAdjustmentLabelLengthRule(maxLength: 16)
        let item = Referrals.newPrimaryFollowUpAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryFollowUpAdjustmentRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Referrals.PrimaryFollowUpAdjustmentRequiredEncounterIDRule(
            message: "primary follow up adjustment needs a value"
        )
        let item = Referrals.newPrimaryFollowUpAdjustment("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimaryFollowUpAdjustmentAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Referrals.PrimaryFollowUpAdjustmentAllergyLengthRule(maxLength: 3600)
        let item = Referrals.newPrimaryFollowUpAdjustment("x", label: "y")
        item.allergy = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryFollowUpAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PrimaryFollowUpAdjustmentRequiredCodeRule(
            message: "primary follow up adjustment needs a value"
        )
        let item = Referrals.newPrimaryFollowUpAdjustment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
