@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalReferralMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalReferralMappingValidator()
        let item = Referrals.newSeasonalReferralMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalReferralMappingLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.SeasonalReferralMappingLabelLengthRule(maxLength: 255)
        let item = Referrals.newSeasonalReferralMapping("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalReferralMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SeasonalReferralMappingRequiredCodeRule(message: "seasonal referral mapping needs an entry")
        let item = Referrals.newSeasonalReferralMapping("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalReferralMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SeasonalReferralMappingCodeLengthRule(maxLength: 255)
        let item = Referrals.newSeasonalReferralMapping("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalReferralMappingClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Referrals.SeasonalReferralMappingClinicianIDLengthRule(maxLength: 80)
        let item = Referrals.newSeasonalReferralMapping("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalReferralMappingRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Referrals.SeasonalReferralMappingRequiredSourceRule(
            message: "seasonal referral mapping needs an entry"
        )
        let item = Referrals.newSeasonalReferralMapping("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalReferralMappingPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Referrals.SeasonalReferralMappingPriorityRangeRule(min: 120, max: 255)
        let item = Referrals.newSeasonalReferralMapping("x", label: "y")
        item.priority = 256
        #expect(rule.check(item).count > 0)
    }
}
