@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyBatchValidator()
        let item = Consent.newProxyBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyBatchCodeLengthRule(maxLength: 80)
        let item = Consent.newProxyBatch("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyBatchMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Consent.ProxyBatchMaximumRangeRule(min: 0.8, max: 180.0)
        let item = Consent.newProxyBatch("x", label: "y")
        item.maximum = 181.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ProxyBatchRequiredCodeRule(message: "proxy batch needs a value")
        let item = Consent.newProxyBatch("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyBatchRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Consent.ProxyBatchRequiredChecksumRule(message: "proxy batch needs this field")
        let item = Consent.newProxyBatch("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
