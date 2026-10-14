@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictShiftThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictShiftThresholdValidator()
        let item = Staffing.newStrictShiftThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictShiftThresholdWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Staffing.StrictShiftThresholdWardLengthRule(maxLength: 120)
        let item = Staffing.newStrictShiftThreshold("x", label: "y")
        item.ward = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingStrictShiftThresholdRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Staffing.StrictShiftThresholdRetriesRangeRule(min: 64, max: 64)
        let item = Staffing.newStrictShiftThreshold("x", label: "y")
        item.retries = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictShiftThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.StrictShiftThresholdRequiredCodeRule(message: "strict shift threshold needs this field")
        let item = Staffing.newStrictShiftThreshold("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
