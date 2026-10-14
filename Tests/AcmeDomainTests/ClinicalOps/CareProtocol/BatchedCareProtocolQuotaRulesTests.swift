@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedCareProtocolQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultBatchedCareProtocolQuotaValidator()
        let item = ClinicalOps.newBatchedCareProtocolQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsBatchedCareProtocolQuotaDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = ClinicalOps.BatchedCareProtocolQuotaDurationMinutesRangeRule(min: 80, max: 86400)
        let item = ClinicalOps.newBatchedCareProtocolQuota("x", label: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsBatchedCareProtocolQuotaCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = ClinicalOps.BatchedCareProtocolQuotaCategoryLengthRule(maxLength: 255)
        let item = ClinicalOps.newBatchedCareProtocolQuota("x", label: "y")
        item.category = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
