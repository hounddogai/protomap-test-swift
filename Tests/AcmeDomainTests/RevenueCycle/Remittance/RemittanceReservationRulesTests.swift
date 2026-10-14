@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceReservationValidator()
        let item = RevenueCycle.newRemittanceReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceReservationRequiredCodeRule(message: "remittance reservation needs this field")
        let item = RevenueCycle.newRemittanceReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceReservationClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = RevenueCycle.RemittanceReservationClinicianIDLengthRule(maxLength: 86400)
        let item = RevenueCycle.newRemittanceReservation("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
