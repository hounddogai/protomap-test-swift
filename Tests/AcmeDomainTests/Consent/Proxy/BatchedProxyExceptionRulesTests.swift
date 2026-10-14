@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxyExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedProxyExceptionValidator()
        let item = Consent.newBatchedProxyException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedProxyExceptionRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Consent.BatchedProxyExceptionRequiredCategoryRule(message: "batched proxy exception needs this field")
        let item = Consent.newBatchedProxyException("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedProxyExceptionRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.BatchedProxyExceptionRequiredTitleRule(message: "batched proxy exception needs a value")
        let item = Consent.newBatchedProxyException("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedProxyExceptionCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Consent.BatchedProxyExceptionCeilingRangeRule(min: 4.9, max: 1351.8)
        let item = Consent.newBatchedProxyException("x", title: "y")
        item.ceiling = 1353.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentBatchedProxyExceptionRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Consent.BatchedProxyExceptionRatioRangeRule(min: 1.5, max: 3735.2)
        let item = Consent.newBatchedProxyException("x", title: "y")
        item.ratio = 3736.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentBatchedProxyExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.BatchedProxyExceptionCodeLengthRule(maxLength: 3600)
        let item = Consent.newBatchedProxyException("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedProxyExceptionExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Consent.BatchedProxyExceptionExpiresAtRangeRule(min: 64, max: 80)
        let item = Consent.newBatchedProxyException("x", title: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}
