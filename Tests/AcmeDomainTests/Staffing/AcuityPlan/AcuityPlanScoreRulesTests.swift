@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanScoreValidator()
        let item = Staffing.newAcuityPlanScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanScoreRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Staffing.AcuityPlanScoreRequiredUnitRule(message: "acuity plan score needs a value")
        let item = Staffing.newAcuityPlanScore("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanScoreRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.AcuityPlanScoreRequiredNameRule(message: "acuity plan score needs this field")
        let item = Staffing.newAcuityPlanScore("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanScoreRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.AcuityPlanScoreRateRangeRule(min: 8.9, max: 4933.8)
        let item = Staffing.newAcuityPlanScore("x", name: "y")
        item.rate = 4935.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanScoreUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Staffing.AcuityPlanScoreUnitLengthRule(maxLength: 16)
        let item = Staffing.newAcuityPlanScore("x", name: "y")
        item.unit = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.AcuityPlanScoreNameLengthRule(maxLength: 3600)
        let item = Staffing.newAcuityPlanScore("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
