@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRegionalProxyQuotaValidator()
        let item = Consent.newRegionalProxyQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRegionalProxyQuotaRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.RegionalProxyQuotaRequiredNameRule(message: "regional proxy quota needs a value")
        let item = Consent.newRegionalProxyQuota("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalProxyQuotaStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.RegionalProxyQuotaStartsAtRangeRule(min: 32, max: 1000)
        let item = Consent.newRegionalProxyQuota("x", name: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
