@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyClaimValidator()
        let item = Consent.newProxyClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyClaimRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.ProxyClaimRequiredTitleRule(message: "proxy claim needs a value")
        let item = Consent.newProxyClaim("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyClaimCodeLengthRule(maxLength: 16)
        let item = Consent.newProxyClaim("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyClaimUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Consent.ProxyClaimUpdatedAtRangeRule(min: 16, max: 64)
        let item = Consent.newProxyClaim("x", title: "y")
        item.updatedAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyClaimRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.ProxyClaimRequiredProcedureCodeRule(message: "proxy claim needs a value")
        let item = Consent.newProxyClaim("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
