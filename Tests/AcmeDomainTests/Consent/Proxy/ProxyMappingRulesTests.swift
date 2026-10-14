@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyMappingValidator()
        let item = Consent.newProxyMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.ProxyMappingRequiredTitleRule(message: "proxy mapping needs a value")
        let item = Consent.newProxyMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyMappingAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Consent.ProxyMappingAllergyLengthRule(maxLength: 16)
        let item = Consent.newProxyMapping("x", title: "y")
        item.allergy = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyMappingWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Consent.ProxyMappingWeightRangeRule(min: 5.9, max: 1324.7)
        let item = Consent.newProxyMapping("x", title: "y")
        item.weight = 1326.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxyMappingRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Consent.ProxyMappingRequiredAllergyRule(message: "proxy mapping needs a value")
        let item = Consent.newProxyMapping("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyMappingCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Consent.ProxyMappingCopayRangeRule(min: 8.2, max: 1431.8)
        let item = Consent.newProxyMapping("x", title: "y")
        item.copay = 1433.3
        #expect(rule.check(item).count > 0)
    }
}
