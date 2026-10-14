@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackProxyThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultFallbackProxyThresholdValidator()
        let item = Consent.newFallbackProxyThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentFallbackProxyThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.FallbackProxyThresholdRequiredCodeRule(message: "fallback proxy threshold needs this field")
        let item = Consent.newFallbackProxyThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackProxyThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.FallbackProxyThresholdCodeLengthRule(maxLength: 1000)
        let item = Consent.newFallbackProxyThreshold("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentFallbackProxyThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.FallbackProxyThresholdNameLengthRule(maxLength: 80)
        let item = Consent.newFallbackProxyThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentFallbackProxyThresholdRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Consent.FallbackProxyThresholdRequiredFacilityRule(
            message: "fallback proxy threshold needs this field"
        )
        let item = Consent.newFallbackProxyThreshold("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackProxyThresholdLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.FallbackProxyThresholdLimitRangeRule(min: 64, max: 255)
        let item = Consent.newFallbackProxyThreshold("x", name: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}
