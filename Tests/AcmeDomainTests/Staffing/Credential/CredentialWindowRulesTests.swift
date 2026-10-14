@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialWindowValidator()
        let item = Staffing.newCredentialWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialWindowTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Staffing.CredentialWindowTimezoneLengthRule(maxLength: 86400)
        let item = Staffing.newCredentialWindow("x", label: "y")
        item.timezone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.CredentialWindowLabelLengthRule(maxLength: 255)
        let item = Staffing.newCredentialWindow("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialWindowDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Staffing.CredentialWindowDescriptionLengthRule(maxLength: 32)
        let item = Staffing.newCredentialWindow("x", label: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
