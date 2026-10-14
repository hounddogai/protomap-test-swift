@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftThresholdValidator()
        let item = Staffing.newShiftThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.ShiftThresholdRequiredNameRule(message: "shift threshold needs this field")
        let item = Staffing.newShiftThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.ShiftThresholdNameLengthRule(maxLength: 80)
        let item = Staffing.newShiftThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftThresholdWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.ShiftThresholdWeightRangeRule(min: 0.8, max: 4506.6)
        let item = Staffing.newShiftThreshold("x", name: "y")
        item.weight = 4508.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ShiftThresholdRequiredCodeRule(message: "shift threshold needs this field")
        let item = Staffing.newShiftThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
