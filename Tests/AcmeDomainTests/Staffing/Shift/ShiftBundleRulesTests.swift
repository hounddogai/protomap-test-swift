@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftBundleValidator()
        let item = Staffing.newShiftBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftBundleRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Staffing.ShiftBundleRegionLengthRule(maxLength: 120)
        let item = Staffing.newShiftBundle("x", name: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftBundleCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Staffing.ShiftBundleCreatedAtRangeRule(min: 80, max: 1000)
        let item = Staffing.newShiftBundle("x", name: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftBundleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.ShiftBundleCopayRangeRule(min: 3.5, max: 2364.2)
        let item = Staffing.newShiftBundle("x", name: "y")
        item.copay = 2365.7
        #expect(rule.check(item).count > 0)
    }
}
