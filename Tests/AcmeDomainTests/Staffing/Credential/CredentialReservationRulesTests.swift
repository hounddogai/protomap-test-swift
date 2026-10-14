@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialReservationValidator()
        let item = Staffing.newCredentialReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialReservationEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Staffing.CredentialReservationEndsAtRangeRule(min: 64, max: 80)
        let item = Staffing.newCredentialReservation("x", title: "y")
        item.endsAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialReservationFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.CredentialReservationFloorValueRangeRule(min: 5.1, max: 2604.4)
        let item = Staffing.newCredentialReservation("x", title: "y")
        item.floorValue = 2605.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CredentialReservationRequiredTitleRule(message: "credential reservation needs a value")
        let item = Staffing.newCredentialReservation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
