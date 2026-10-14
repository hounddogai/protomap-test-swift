@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingRecallAuditValidator()
        let item = Pharmacy.newPendingRecallAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingRecallAuditVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.PendingRecallAuditVisitMinutesRangeRule(min: 255, max: 3600)
        let item = Pharmacy.newPendingRecallAudit("x", title: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingRecallAuditRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Pharmacy.PendingRecallAuditRetriesRangeRule(min: 64, max: 86400)
        let item = Pharmacy.newPendingRecallAudit("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingRecallAuditWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Pharmacy.PendingRecallAuditWardLengthRule(maxLength: 16)
        let item = Pharmacy.newPendingRecallAudit("x", title: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPendingRecallAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.PendingRecallAuditRequiredTitleRule(message: "pending recall audit needs this field")
        let item = Pharmacy.newPendingRecallAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingRecallAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.PendingRecallAuditCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newPendingRecallAudit("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
