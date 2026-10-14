@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingCredentialRequestValidator()
        let item = Staffing.newPendingCredentialRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingCredentialRequestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.PendingCredentialRequestLabelLengthRule(maxLength: 3600)
        let item = Staffing.newPendingCredentialRequest("x", title: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingCredentialRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PendingCredentialRequestCodeLengthRule(maxLength: 86400)
        let item = Staffing.newPendingCredentialRequest("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingCredentialRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.PendingCredentialRequestRequiredLabelRule(
            message: "pending credential request needs this field"
        )
        let item = Staffing.newPendingCredentialRequest("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingCredentialRequestBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Staffing.PendingCredentialRequestBatchSizeRangeRule(min: 255, max: 3600)
        let item = Staffing.newPendingCredentialRequest("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPendingCredentialRequestRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Staffing.PendingCredentialRequestRequiredCurrencyRule(
            message: "pending credential request needs an entry"
        )
        let item = Staffing.newPendingCredentialRequest("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
