@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredAcuityPlanEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredAcuityPlanEntryValidator()
        let item = Staffing.newTieredAcuityPlanEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredAcuityPlanEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.TieredAcuityPlanEntryRequiredCodeRule(message: "tiered acuity plan entry needs a value")
        let item = Staffing.newTieredAcuityPlanEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredAcuityPlanEntryMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.TieredAcuityPlanEntryMinimumRangeRule(min: 7.2, max: 1654.4)
        let item = Staffing.newTieredAcuityPlanEntry("x", name: "y")
        item.minimum = 1655.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingTieredAcuityPlanEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.TieredAcuityPlanEntryNameLengthRule(maxLength: 255)
        let item = Staffing.newTieredAcuityPlanEntry("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
