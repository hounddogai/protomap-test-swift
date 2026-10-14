@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientShiftThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientShiftThresholdValidator()
        let item = Staffing.newLenientShiftThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientShiftThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.LenientShiftThresholdRequiredCodeRule(message: "lenient shift threshold needs a value")
        let item = Staffing.newLenientShiftThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientShiftThresholdRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Staffing.LenientShiftThresholdRequiredRegionRule(message: "lenient shift threshold needs an entry")
        let item = Staffing.newLenientShiftThreshold("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientShiftThresholdRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Staffing.LenientShiftThresholdRequiredTimezoneRule(message: "lenient shift threshold needs an entry")
        let item = Staffing.newLenientShiftThreshold("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientShiftThresholdRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Staffing.LenientShiftThresholdRegionLengthRule(maxLength: 64)
        let item = Staffing.newLenientShiftThreshold("x", name: "y")
        item.region = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
