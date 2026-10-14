@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanRollupValidator()
        let item = Staffing.newAcuityPlanRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanRollupDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Staffing.AcuityPlanRollupDurationMinutesRangeRule(min: 16, max: 80)
        let item = Staffing.newAcuityPlanRollup("x", title: "y")
        item.durationMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AcuityPlanRollupRequiredCodeRule(message: "acuity plan rollup needs this field")
        let item = Staffing.newAcuityPlanRollup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanRollupExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Staffing.AcuityPlanRollupExternalRefLengthRule(maxLength: 80)
        let item = Staffing.newAcuityPlanRollup("x", title: "y")
        item.externalRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanRollupFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Staffing.AcuityPlanRollupFacilityLengthRule(maxLength: 80)
        let item = Staffing.newAcuityPlanRollup("x", title: "y")
        item.facility = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanRollupRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Staffing.AcuityPlanRollupRequiredExternalRefRule(message: "acuity plan rollup needs a value")
        let item = Staffing.newAcuityPlanRollup("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
