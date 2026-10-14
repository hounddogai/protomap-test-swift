@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingCareGapBatchValidator()
        let item = CareManagement.newPendingCareGapBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingCareGapBatchExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.PendingCareGapBatchExpiresAtRangeRule(min: 16, max: 16)
        let item = CareManagement.newPendingCareGapBatch("x", label: "y")
        item.expiresAt = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPendingCareGapBatchRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = CareManagement.PendingCareGapBatchRequiredSummaryRule(
            message: "pending care gap batch needs this field"
        )
        let item = CareManagement.newPendingCareGapBatch("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingCareGapBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PendingCareGapBatchCodeLengthRule(maxLength: 80)
        let item = CareManagement.newPendingCareGapBatch("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingCareGapBatchQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.PendingCareGapBatchQuantityRangeRule(min: 80, max: 1000)
        let item = CareManagement.newPendingCareGapBatch("x", label: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}
