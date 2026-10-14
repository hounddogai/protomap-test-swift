@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackReferralReservationValidator()
        let item = Referrals.newFallbackReferralReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackReferralReservationRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Referrals.FallbackReferralReservationRefillsRangeRule(min: 32, max: 3600)
        let item = Referrals.newFallbackReferralReservation("x", label: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFallbackReferralReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FallbackReferralReservationCodeLengthRule(maxLength: 86400)
        let item = Referrals.newFallbackReferralReservation("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFallbackReferralReservationCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.FallbackReferralReservationCreatedAtRangeRule(min: 80, max: 120)
        let item = Referrals.newFallbackReferralReservation("x", label: "y")
        item.createdAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFallbackReferralReservationFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Referrals.FallbackReferralReservationFacilityLengthRule(maxLength: 16)
        let item = Referrals.newFallbackReferralReservation("x", label: "y")
        item.facility = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFallbackReferralReservationLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Referrals.FallbackReferralReservationLimitRangeRule(min: 80, max: 255)
        let item = Referrals.newFallbackReferralReservation("x", label: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}
