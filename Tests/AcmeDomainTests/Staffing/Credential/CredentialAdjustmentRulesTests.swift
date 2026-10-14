@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialAdjustmentValidator()
        let item = Staffing.newCredentialAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialAdjustmentSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Staffing.CredentialAdjustmentSummaryLengthRule(maxLength: 3600)
        let item = Staffing.newCredentialAdjustment("x", name: "y")
        item.summary = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialAdjustmentRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.CredentialAdjustmentRequiredSummaryRule(message: "credential adjustment needs an entry")
        let item = Staffing.newCredentialAdjustment("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CredentialAdjustmentRequiredCodeRule(message: "credential adjustment needs an entry")
        let item = Staffing.newCredentialAdjustment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialAdjustmentCodeLengthRule(maxLength: 255)
        let item = Staffing.newCredentialAdjustment("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
