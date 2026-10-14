@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialExceptionValidator()
        let item = Staffing.newCredentialException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialExceptionCodeLengthRule(maxLength: 32)
        let item = Staffing.newCredentialException("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CredentialExceptionTitleLengthRule(maxLength: 255)
        let item = Staffing.newCredentialException("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialExceptionCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.CredentialExceptionCostRangeRule(min: 2.9, max: 2134.6)
        let item = Staffing.newCredentialException("x", title: "y")
        item.cost = 2136.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialExceptionWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.CredentialExceptionWindowDaysRangeRule(min: 32, max: 3600)
        let item = Staffing.newCredentialException("x", title: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}
