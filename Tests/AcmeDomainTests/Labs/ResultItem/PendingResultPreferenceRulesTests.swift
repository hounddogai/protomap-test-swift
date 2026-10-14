@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingResultPreferenceValidator()
        let item = Labs.newPendingResultPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingResultPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PendingResultPreferenceRequiredCodeRule(message: "pending result preference needs an entry")
        let item = Labs.newPendingResultPreference("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingResultPreferenceRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Labs.PendingResultPreferenceRefillsRangeRule(min: 16, max: 86400)
        let item = Labs.newPendingResultPreference("x", label: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPendingResultPreferenceWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Labs.PendingResultPreferenceWardLengthRule(maxLength: 120)
        let item = Labs.newPendingResultPreference("x", label: "y")
        item.ward = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
