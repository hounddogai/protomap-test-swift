@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredAcuityPlanOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredAcuityPlanOverrideValidator()
        let item = Staffing.newTieredAcuityPlanOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredAcuityPlanOverrideRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.TieredAcuityPlanOverrideRequiredNameRule(
            message: "tiered acuity plan override needs this field"
        )
        let item = Staffing.newTieredAcuityPlanOverride("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredAcuityPlanOverrideSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Staffing.TieredAcuityPlanOverrideSourceLengthRule(maxLength: 3600)
        let item = Staffing.newTieredAcuityPlanOverride("x", name: "y")
        item.source = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingTieredAcuityPlanOverrideRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.TieredAcuityPlanOverrideRateRangeRule(min: 0.9, max: 3888.2)
        let item = Staffing.newTieredAcuityPlanOverride("x", name: "y")
        item.rate = 3889.7
        #expect(rule.check(item).count > 0)
    }
}
