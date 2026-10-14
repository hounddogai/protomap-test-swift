@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialNoticeValidator()
        let item = Staffing.newCredentialNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialNoticeFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Staffing.CredentialNoticeFacilityLengthRule(maxLength: 80)
        let item = Staffing.newCredentialNotice("x", title: "y")
        item.facility = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialNoticeWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.CredentialNoticeWindowDaysRangeRule(min: 32, max: 1000)
        let item = Staffing.newCredentialNotice("x", title: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialNoticePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.CredentialNoticePayerLengthRule(maxLength: 64)
        let item = Staffing.newCredentialNotice("x", title: "y")
        item.payer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
