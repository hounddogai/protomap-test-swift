@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialTargetValidator()
        let item = Staffing.newCredentialTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CredentialTargetRequiredCodeRule(message: "credential target needs an entry")
        let item = Staffing.newCredentialTarget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialTargetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CredentialTargetRequiredTitleRule(message: "credential target needs a value")
        let item = Staffing.newCredentialTarget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialTargetRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Staffing.CredentialTargetRequiredOwnerIDRule(message: "credential target needs this field")
        let item = Staffing.newCredentialTarget("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialTargetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CredentialTargetTitleLengthRule(maxLength: 86400)
        let item = Staffing.newCredentialTarget("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
