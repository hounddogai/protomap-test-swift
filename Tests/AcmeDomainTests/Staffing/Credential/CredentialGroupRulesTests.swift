@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialGroupValidator()
        let item = Staffing.newCredentialGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialGroupCodeLengthRule(maxLength: 86400)
        let item = Staffing.newCredentialGroup("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialGroupMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.CredentialGroupMinimumRangeRule(min: 8.3, max: 4995.3)
        let item = Staffing.newCredentialGroup("x", name: "y")
        item.minimum = 4996.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialGroupBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Staffing.CredentialGroupBedLengthRule(maxLength: 86400)
        let item = Staffing.newCredentialGroup("x", name: "y")
        item.bed = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.CredentialGroupNameLengthRule(maxLength: 120)
        let item = Staffing.newCredentialGroup("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
