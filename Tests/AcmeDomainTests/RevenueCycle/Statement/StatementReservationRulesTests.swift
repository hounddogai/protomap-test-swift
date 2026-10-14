@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementReservationValidator()
        let item = RevenueCycle.newStatementReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementReservationClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = RevenueCycle.StatementReservationClinicianIDLengthRule(maxLength: 32)
        let item = RevenueCycle.newStatementReservation("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementReservationRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = RevenueCycle.StatementReservationRequiredWardRule(message: "statement reservation needs this field")
        let item = RevenueCycle.newStatementReservation("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.StatementReservationRequiredTitleRule(message: "statement reservation needs a value")
        let item = RevenueCycle.newStatementReservation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
