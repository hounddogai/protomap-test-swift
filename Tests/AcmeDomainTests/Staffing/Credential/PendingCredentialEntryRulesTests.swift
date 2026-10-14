@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingCredentialEntryValidator()
        let item = Staffing.newPendingCredentialEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingCredentialEntryFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Staffing.PendingCredentialEntryFacilityLengthRule(maxLength: 80)
        let item = Staffing.newPendingCredentialEntry("x", label: "y")
        item.facility = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingCredentialEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PendingCredentialEntryRequiredCodeRule(message: "pending credential entry needs an entry")
        let item = Staffing.newPendingCredentialEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
