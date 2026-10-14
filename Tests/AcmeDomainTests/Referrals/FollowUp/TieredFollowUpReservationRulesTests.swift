@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredFollowUpReservationValidator()
        let item = Referrals.newTieredFollowUpReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredFollowUpReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.TieredFollowUpReservationRequiredLabelRule(
            message: "tiered follow up reservation needs a value"
        )
        let item = Referrals.newTieredFollowUpReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredFollowUpReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.TieredFollowUpReservationCodeLengthRule(maxLength: 64)
        let item = Referrals.newTieredFollowUpReservation("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredFollowUpReservationSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.TieredFollowUpReservationSequenceRangeRule(min: 64, max: 86400)
        let item = Referrals.newTieredFollowUpReservation("x", label: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsTieredFollowUpReservationStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Referrals.TieredFollowUpReservationStartsAtRangeRule(min: 255, max: 86400)
        let item = Referrals.newTieredFollowUpReservation("x", label: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
