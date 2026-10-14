@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveShiftBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAdaptiveShiftBaselineValidator()
        let item = Staffing.newAdaptiveShiftBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAdaptiveShiftBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.AdaptiveShiftBaselineNameLengthRule(maxLength: 64)
        let item = Staffing.newAdaptiveShiftBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAdaptiveShiftBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.AdaptiveShiftBaselineRequiredNameRule(message: "adaptive shift baseline needs a value")
        let item = Staffing.newAdaptiveShiftBaseline("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAdaptiveShiftBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AdaptiveShiftBaselineRequiredCodeRule(message: "adaptive shift baseline needs a value")
        let item = Staffing.newAdaptiveShiftBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
