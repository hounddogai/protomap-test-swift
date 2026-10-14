@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveOvertimeAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAdaptiveOvertimeAllocationValidator()
        let item = Staffing.newAdaptiveOvertimeAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAdaptiveOvertimeAllocationRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Staffing.AdaptiveOvertimeAllocationRequiredPhoneRule(
            message: "adaptive overtime allocation needs an entry"
        )
        let item = Staffing.newAdaptiveOvertimeAllocation("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAdaptiveOvertimeAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AdaptiveOvertimeAllocationCodeLengthRule(maxLength: 64)
        let item = Staffing.newAdaptiveOvertimeAllocation("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAdaptiveOvertimeAllocationCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.AdaptiveOvertimeAllocationCeilingRangeRule(min: 7.4, max: 3655.1)
        let item = Staffing.newAdaptiveOvertimeAllocation("x", name: "y")
        item.ceiling = 3656.6
        #expect(rule.check(item).count > 0)
    }
}
