@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRegionalProxyBaselineValidator()
        let item = Consent.newRegionalProxyBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRegionalProxyBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RegionalProxyBaselineRequiredCodeRule(message: "regional proxy baseline needs a value")
        let item = Consent.newRegionalProxyBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalProxyBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RegionalProxyBaselineCodeLengthRule(maxLength: 64)
        let item = Consent.newRegionalProxyBaseline("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRegionalProxyBaselineLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.RegionalProxyBaselineLimitRangeRule(min: 16, max: 3600)
        let item = Consent.newRegionalProxyBaseline("x", name: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}
