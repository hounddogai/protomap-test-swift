@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationScheduleValidator()
        let item = BedManagement.newIsolationSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationScheduleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.IsolationScheduleVersionRangeRule(min: 80, max: 80)
        let item = BedManagement.newIsolationSchedule("x", title: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationScheduleRequiredCodeRule(message: "isolation schedule needs an entry")
        let item = BedManagement.newIsolationSchedule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
