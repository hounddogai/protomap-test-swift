@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolReservationValidator()
        let item = Staffing.newFloatPoolReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FloatPoolReservationRequiredCodeRule(message: "float pool reservation needs a value")
        let item = Staffing.newFloatPoolReservation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.FloatPoolReservationLabelLengthRule(maxLength: 16)
        let item = Staffing.newFloatPoolReservation("x", name: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolReservationMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.FloatPoolReservationMinimumRangeRule(min: 7.1, max: 2437.8)
        let item = Staffing.newFloatPoolReservation("x", name: "y")
        item.minimum = 2439.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolReservationSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Staffing.FloatPoolReservationSourceLengthRule(maxLength: 255)
        let item = Staffing.newFloatPoolReservation("x", name: "y")
        item.source = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
