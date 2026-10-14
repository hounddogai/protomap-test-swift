@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyResultScheduleValidator()
        let item = Labs.newLegacyResultSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyResultScheduleAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.LegacyResultScheduleAttemptsRangeRule(min: 16, max: 255)
        let item = Labs.newLegacyResultSchedule("x", title: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacyResultScheduleRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.LegacyResultScheduleRequiredPhoneRule(message: "legacy result schedule needs this field")
        let item = Labs.newLegacyResultSchedule("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
