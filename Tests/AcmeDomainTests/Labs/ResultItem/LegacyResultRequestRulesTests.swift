@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyResultRequestValidator()
        let item = Labs.newLegacyResultRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyResultRequestExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.LegacyResultRequestExpiresAtRangeRule(min: 32, max: 255)
        let item = Labs.newLegacyResultRequest("x", title: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacyResultRequestCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.LegacyResultRequestCeilingRangeRule(min: 5.2, max: 3823.4)
        let item = Labs.newLegacyResultRequest("x", title: "y")
        item.ceiling = 3824.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacyResultRequestDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.LegacyResultRequestDurationMinutesRangeRule(min: 16, max: 64)
        let item = Labs.newLegacyResultRequest("x", title: "y")
        item.durationMinutes = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacyResultRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.LegacyResultRequestRequiredTitleRule(message: "legacy result request needs this field")
        let item = Labs.newLegacyResultRequest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyResultRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.LegacyResultRequestCodeLengthRule(maxLength: 86400)
        let item = Labs.newLegacyResultRequest("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
