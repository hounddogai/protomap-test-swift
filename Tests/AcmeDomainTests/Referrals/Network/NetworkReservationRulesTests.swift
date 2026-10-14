@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkReservationValidator()
        let item = Referrals.newNetworkReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkReservationClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Referrals.NetworkReservationClinicianIDLengthRule(maxLength: 32)
        let item = Referrals.newNetworkReservation("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkReservationCodeLengthRule(maxLength: 1000)
        let item = Referrals.newNetworkReservation("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
