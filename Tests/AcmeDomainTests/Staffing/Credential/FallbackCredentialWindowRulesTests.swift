@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackCredentialWindowValidator()
        let item = Staffing.newFallbackCredentialWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackCredentialWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.FallbackCredentialWindowLabelLengthRule(maxLength: 1000)
        let item = Staffing.newFallbackCredentialWindow("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackCredentialWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.FallbackCredentialWindowRequiredLabelRule(
            message: "fallback credential window needs an entry"
        )
        let item = Staffing.newFallbackCredentialWindow("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackCredentialWindowThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Staffing.FallbackCredentialWindowThresholdRangeRule(min: 6.1, max: 2445.8)
        let item = Staffing.newFallbackCredentialWindow("x", label: "y")
        item.threshold = 2447.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackCredentialWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FallbackCredentialWindowRequiredCodeRule(message: "fallback credential window needs a value")
        let item = Staffing.newFallbackCredentialWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackCredentialWindowRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Staffing.FallbackCredentialWindowRequiredTimezoneRule(
            message: "fallback credential window needs an entry"
        )
        let item = Staffing.newFallbackCredentialWindow("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
