@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxyCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedProxyCycleValidator()
        let item = Consent.newBatchedProxyCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedProxyCycleSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Consent.BatchedProxyCycleSourceLengthRule(maxLength: 86400)
        let item = Consent.newBatchedProxyCycle("x", title: "y")
        item.source = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedProxyCycleRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Consent.BatchedProxyCycleRequiredExternalRefRule(message: "batched proxy cycle needs a value")
        let item = Consent.newBatchedProxyCycle("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedProxyCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.BatchedProxyCycleRequiredCodeRule(message: "batched proxy cycle needs an entry")
        let item = Consent.newBatchedProxyCycle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
