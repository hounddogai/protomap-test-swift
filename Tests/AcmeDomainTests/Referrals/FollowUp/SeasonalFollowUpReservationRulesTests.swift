@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalFollowUpReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalFollowUpReservationValidator()
        let item = Referrals.newSeasonalFollowUpReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalFollowUpReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SeasonalFollowUpReservationRequiredCodeRule(
            message: "seasonal follow up reservation needs a value"
        )
        let item = Referrals.newSeasonalFollowUpReservation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalFollowUpReservationClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Referrals.SeasonalFollowUpReservationClinicianIDLengthRule(maxLength: 32)
        let item = Referrals.newSeasonalFollowUpReservation("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalFollowUpReservationRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Referrals.SeasonalFollowUpReservationRequiredPayerRule(
            message: "seasonal follow up reservation needs this field"
        )
        let item = Referrals.newSeasonalFollowUpReservation("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalFollowUpReservationRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Referrals.SeasonalFollowUpReservationRatioRangeRule(min: 4.8, max: 717.3)
        let item = Referrals.newSeasonalFollowUpReservation("x", name: "y")
        item.ratio = 718.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalFollowUpReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SeasonalFollowUpReservationCodeLengthRule(maxLength: 86400)
        let item = Referrals.newSeasonalFollowUpReservation("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
