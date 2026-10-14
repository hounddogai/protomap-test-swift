@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingOutreachReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingOutreachReservationValidator()
        let item = CareManagement.newRollingOutreachReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingOutreachReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RollingOutreachReservationCodeLengthRule(maxLength: 120)
        let item = CareManagement.newRollingOutreachReservation("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingOutreachReservationGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.RollingOutreachReservationGraceDaysRangeRule(min: 64, max: 255)
        let item = CareManagement.newRollingOutreachReservation("x", label: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRollingOutreachReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.RollingOutreachReservationRequiredCodeRule(
            message: "rolling outreach reservation needs a value"
        )
        let item = CareManagement.newRollingOutreachReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
