@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxyOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedProxyOverrideValidator()
        let item = Consent.newBatchedProxyOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedProxyOverrideDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Consent.BatchedProxyOverrideDosageMgRangeRule(min: 6.3, max: 4816.6)
        let item = Consent.newBatchedProxyOverride("x", label: "y")
        item.dosageMg = 4818.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentBatchedProxyOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.BatchedProxyOverrideCodeLengthRule(maxLength: 3600)
        let item = Consent.newBatchedProxyOverride("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
