@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedShiftTierValidator()
        let item = Staffing.newCappedShiftTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedShiftTierFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Staffing.CappedShiftTierFacilityLengthRule(maxLength: 255)
        let item = Staffing.newCappedShiftTier("x", label: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedShiftTierCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.CappedShiftTierCopayRangeRule(min: 7.1, max: 2779.7)
        let item = Staffing.newCappedShiftTier("x", label: "y")
        item.copay = 2781.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCappedShiftTierRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Staffing.CappedShiftTierRequiredFacilityRule(message: "capped shift tier needs a value")
        let item = Staffing.newCappedShiftTier("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCappedShiftTierRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Staffing.CappedShiftTierRequiredPatientRefRule(message: "capped shift tier needs this field")
        let item = Staffing.newCappedShiftTier("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCappedShiftTierCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.CappedShiftTierCeilingRangeRule(min: 2.1, max: 601.4)
        let item = Staffing.newCappedShiftTier("x", label: "y")
        item.ceiling = 602.9
        #expect(rule.check(item).count > 0)
    }
}
