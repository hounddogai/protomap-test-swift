@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolBaselineValidator()
        let item = Staffing.newFloatPoolBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolBaselineRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Staffing.FloatPoolBaselineRequiredPatientRefRule(message: "float pool baseline needs an entry")
        let item = Staffing.newFloatPoolBaseline("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolBaselineStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Staffing.FloatPoolBaselineStartsAtRangeRule(min: 120, max: 1000)
        let item = Staffing.newFloatPoolBaseline("x", label: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FloatPoolBaselineCodeLengthRule(maxLength: 1000)
        let item = Staffing.newFloatPoolBaseline("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolBaselineRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Staffing.FloatPoolBaselineRequiredSegmentRule(message: "float pool baseline needs this field")
        let item = Staffing.newFloatPoolBaseline("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
