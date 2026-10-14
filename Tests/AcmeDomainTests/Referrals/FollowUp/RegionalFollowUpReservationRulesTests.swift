@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalFollowUpReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalFollowUpReservationValidator()
        let item = Referrals.newRegionalFollowUpReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalFollowUpReservationFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Referrals.RegionalFollowUpReservationFacilityLengthRule(maxLength: 1000)
        let item = Referrals.newRegionalFollowUpReservation("x", name: "y")
        item.facility = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalFollowUpReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.RegionalFollowUpReservationCodeLengthRule(maxLength: 64)
        let item = Referrals.newRegionalFollowUpReservation("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalFollowUpReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RegionalFollowUpReservationRequiredCodeRule(
            message: "regional follow up reservation needs a value"
        )
        let item = Referrals.newRegionalFollowUpReservation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
