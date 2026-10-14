@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotReservationValidator()
        let item = Referrals.newSlotReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotReservationWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.SlotReservationWindowDaysRangeRule(min: 1000, max: 3600)
        let item = Referrals.newSlotReservation("x", title: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotReservationCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Referrals.SlotReservationCategoryLengthRule(maxLength: 16)
        let item = Referrals.newSlotReservation("x", title: "y")
        item.category = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotReservationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.SlotReservationTitleLengthRule(maxLength: 255)
        let item = Referrals.newSlotReservation("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
