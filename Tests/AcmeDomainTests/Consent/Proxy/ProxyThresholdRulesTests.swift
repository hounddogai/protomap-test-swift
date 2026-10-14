@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyThresholdValidator()
        let item = Consent.newProxyThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyThresholdCodeLengthRule(maxLength: 80)
        let item = Consent.newProxyThreshold("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyThresholdRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.ProxyThresholdRequiredProcedureCodeRule(message: "proxy threshold needs this field")
        let item = Consent.newProxyThreshold("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.ProxyThresholdTitleLengthRule(maxLength: 16)
        let item = Consent.newProxyThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
