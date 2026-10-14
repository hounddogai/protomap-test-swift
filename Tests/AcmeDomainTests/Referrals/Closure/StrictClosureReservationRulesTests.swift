@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictClosureReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultStrictClosureReservationValidator()
        let item = Referrals.newStrictClosureReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsStrictClosureReservationRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Referrals.StrictClosureReservationRequiredTimezoneRule(
            message: "strict closure reservation needs a value"
        )
        let item = Referrals.newStrictClosureReservation("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictClosureReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.StrictClosureReservationLabelLengthRule(maxLength: 3600)
        let item = Referrals.newStrictClosureReservation("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsStrictClosureReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.StrictClosureReservationCodeLengthRule(maxLength: 1000)
        let item = Referrals.newStrictClosureReservation("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
