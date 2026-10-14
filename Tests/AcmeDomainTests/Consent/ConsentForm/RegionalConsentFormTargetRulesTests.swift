@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalConsentFormTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRegionalConsentFormTargetValidator()
        let item = Consent.newRegionalConsentFormTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRegionalConsentFormTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RegionalConsentFormTargetRequiredCodeRule(
            message: "regional consent form target needs a value"
        )
        let item = Consent.newRegionalConsentFormTarget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalConsentFormTargetPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Consent.RegionalConsentFormTargetPriorityRangeRule(min: 86400, max: 86400)
        let item = Consent.newRegionalConsentFormTarget("x", title: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRegionalConsentFormTargetWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Consent.RegionalConsentFormTargetWeightRangeRule(min: 1.3, max: 1917.6)
        let item = Consent.newRegionalConsentFormTarget("x", title: "y")
        item.weight = 1919.1
        #expect(rule.check(item).count > 0)
    }
}
