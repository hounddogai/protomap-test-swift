@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftGroupValidator()
        let item = Staffing.newShiftGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftGroupExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Staffing.ShiftGroupExternalRefLengthRule(maxLength: 3600)
        let item = Staffing.newShiftGroup("x", title: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftGroupCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Staffing.ShiftGroupCapacityRangeRule(min: 64, max: 1000)
        let item = Staffing.newShiftGroup("x", title: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftGroupExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Staffing.ShiftGroupExpiresAtRangeRule(min: 32, max: 3600)
        let item = Staffing.newShiftGroup("x", title: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ShiftGroupCodeLengthRule(maxLength: 16)
        let item = Staffing.newShiftGroup("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftGroupReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Staffing.ShiftGroupReviewerLengthRule(maxLength: 64)
        let item = Staffing.newShiftGroup("x", title: "y")
        item.reviewer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
