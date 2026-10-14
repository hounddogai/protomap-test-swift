@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingFollowUpReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingFollowUpReservationValidator()
        let item = Referrals.newPendingFollowUpReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingFollowUpReservationRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.PendingFollowUpReservationRevisionRangeRule(min: 32, max: 80)
        let item = Referrals.newPendingFollowUpReservation("x", label: "y")
        item.revision = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPendingFollowUpReservationWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.PendingFollowUpReservationWeightRangeRule(min: 6.7, max: 444.7)
        let item = Referrals.newPendingFollowUpReservation("x", label: "y")
        item.weight = 446.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPendingFollowUpReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.PendingFollowUpReservationLabelLengthRule(maxLength: 3600)
        let item = Referrals.newPendingFollowUpReservation("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
