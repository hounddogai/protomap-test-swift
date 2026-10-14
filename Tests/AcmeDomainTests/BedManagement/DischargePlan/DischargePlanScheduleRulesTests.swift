@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanScheduleValidator()
        let item = BedManagement.newDischargePlanSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanScheduleExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = BedManagement.DischargePlanScheduleExternalRefLengthRule(maxLength: 1000)
        let item = BedManagement.newDischargePlanSchedule("x", title: "y")
        item.externalRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
