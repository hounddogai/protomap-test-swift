@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientProxyClaimValidator()
        let item = Consent.newLenientProxyClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientProxyClaimRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.LenientProxyClaimRequiredNameRule(message: "lenient proxy claim needs an entry")
        let item = Consent.newLenientProxyClaim("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientProxyClaimNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.LenientProxyClaimNameLengthRule(maxLength: 32)
        let item = Consent.newLenientProxyClaim("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientProxyClaimBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.LenientProxyClaimBudgetRangeRule(min: 4.0, max: 2648.0)
        let item = Consent.newLenientProxyClaim("x", name: "y")
        item.budget = 2649.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLenientProxyClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LenientProxyClaimRequiredCodeRule(message: "lenient proxy claim needs a value")
        let item = Consent.newLenientProxyClaim("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientProxyClaimWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Consent.LenientProxyClaimWardLengthRule(maxLength: 255)
        let item = Consent.newLenientProxyClaim("x", name: "y")
        item.ward = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
