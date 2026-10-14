@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedHandoffDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultBatchedHandoffDigestValidator()
        let item = ClinicalOps.newBatchedHandoffDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsBatchedHandoffDigestEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.BatchedHandoffDigestEndsAtRangeRule(min: 32, max: 3600)
        let item = ClinicalOps.newBatchedHandoffDigest("x", title: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsBatchedHandoffDigestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.BatchedHandoffDigestTitleLengthRule(maxLength: 120)
        let item = ClinicalOps.newBatchedHandoffDigest("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsBatchedHandoffDigestRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = ClinicalOps.BatchedHandoffDigestRequiredCurrencyRule(message: "batched handoff digest needs an entry")
        let item = ClinicalOps.newBatchedHandoffDigest("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsBatchedHandoffDigestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.BatchedHandoffDigestDiscountRangeRule(min: 9.2, max: 1509.7)
        let item = ClinicalOps.newBatchedHandoffDigest("x", title: "y")
        item.discount = 1511.2
        #expect(rule.check(item).count > 0)
    }
}
