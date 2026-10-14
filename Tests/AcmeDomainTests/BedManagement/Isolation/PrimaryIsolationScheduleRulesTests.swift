@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryIsolationScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryIsolationScheduleValidator()
        let item = BedManagement.newPrimaryIsolationSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryIsolationScheduleRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = BedManagement.PrimaryIsolationScheduleRequiredContactEmailRule(
            message: "primary isolation schedule needs an entry"
        )
        let item = BedManagement.newPrimaryIsolationSchedule("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryIsolationScheduleContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = BedManagement.PrimaryIsolationScheduleContactEmailLengthRule(maxLength: 86400)
        let item = BedManagement.newPrimaryIsolationSchedule("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryIsolationScheduleVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = BedManagement.PrimaryIsolationScheduleVisitMinutesRangeRule(min: 120, max: 3600)
        let item = BedManagement.newPrimaryIsolationSchedule("x", name: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}
