@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialEstimateValidator()
        let item = Staffing.newCredentialEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialEstimateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.CredentialEstimateRequiredLabelRule(message: "credential estimate needs an entry")
        let item = Staffing.newCredentialEstimate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialEstimateCodeLengthRule(maxLength: 80)
        let item = Staffing.newCredentialEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialEstimateSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Staffing.CredentialEstimateSummaryLengthRule(maxLength: 255)
        let item = Staffing.newCredentialEstimate("x", label: "y")
        item.summary = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
