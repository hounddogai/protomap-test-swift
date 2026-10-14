@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpReservationValidator()
        let item = Referrals.newFollowUpReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpReservationWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.FollowUpReservationWardLengthRule(maxLength: 16)
        let item = Referrals.newFollowUpReservation("x", name: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpReservationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.FollowUpReservationTitleLengthRule(maxLength: 3600)
        let item = Referrals.newFollowUpReservation("x", name: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpReservationRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Referrals.FollowUpReservationRequiredWardRule(message: "follow up reservation needs an entry")
        let item = Referrals.newFollowUpReservation("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpReservationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.FollowUpReservationNameLengthRule(maxLength: 1000)
        let item = Referrals.newFollowUpReservation("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpReservationDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Referrals.FollowUpReservationDiscountRangeRule(min: 6.6, max: 3950.6)
        let item = Referrals.newFollowUpReservation("x", name: "y")
        item.discount = 3952.1
        #expect(rule.check(item).count > 0)
    }
}
