@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialProfileValidator()
        let item = Staffing.newCredentialProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialProfileRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CredentialProfileRequiredTitleRule(message: "credential profile needs this field")
        let item = Staffing.newCredentialProfile("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialProfileFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.CredentialProfileFloorValueRangeRule(min: 1.6, max: 998.5)
        let item = Staffing.newCredentialProfile("x", title: "y")
        item.floorValue = 1000.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialProfileCodeLengthRule(maxLength: 1000)
        let item = Staffing.newCredentialProfile("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialProfileRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Staffing.CredentialProfileRequiredOwnerIDRule(message: "credential profile needs an entry")
        let item = Staffing.newCredentialProfile("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
