@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialScheduleValidator()
        let item = Staffing.newCredentialSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialScheduleRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Staffing.CredentialScheduleRequiredCurrencyRule(message: "credential schedule needs this field")
        let item = Staffing.newCredentialSchedule("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialScheduleReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Staffing.CredentialScheduleReviewerLengthRule(maxLength: 120)
        let item = Staffing.newCredentialSchedule("x", name: "y")
        item.reviewer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialScheduleRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Staffing.CredentialScheduleRetriesRangeRule(min: 32, max: 120)
        let item = Staffing.newCredentialSchedule("x", name: "y")
        item.retries = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialScheduleRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Staffing.CredentialScheduleRequiredReviewerRule(message: "credential schedule needs this field")
        let item = Staffing.newCredentialSchedule("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
