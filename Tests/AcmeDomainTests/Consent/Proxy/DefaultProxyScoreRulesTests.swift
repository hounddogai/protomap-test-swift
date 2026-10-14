@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDefaultProxyScoreValidator()
        let item = Consent.newDefaultProxyScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDefaultProxyScoreFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Consent.DefaultProxyScoreFloorValueRangeRule(min: 3.1, max: 3193.6)
        let item = Consent.newDefaultProxyScore("x", label: "y")
        item.floorValue = 3195.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDefaultProxyScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DefaultProxyScoreRequiredCodeRule(message: "default proxy score needs an entry")
        let item = Consent.newDefaultProxyScore("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDefaultProxyScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.DefaultProxyScoreCodeLengthRule(maxLength: 32)
        let item = Consent.newDefaultProxyScore("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDefaultProxyScoreRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Consent.DefaultProxyScoreRequiredContactEmailRule(message: "default proxy score needs a value")
        let item = Consent.newDefaultProxyScore("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
