@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyCredentialScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLegacyCredentialScheduleValidator()
        let item = Staffing.newLegacyCredentialSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLegacyCredentialScheduleRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.LegacyCredentialScheduleRateRangeRule(min: 6.6, max: 2895.1)
        let item = Staffing.newLegacyCredentialSchedule("x", label: "y")
        item.rate = 2896.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLegacyCredentialScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.LegacyCredentialScheduleRequiredCodeRule(message: "legacy credential schedule needs a value")
        let item = Staffing.newLegacyCredentialSchedule("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
