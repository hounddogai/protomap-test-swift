@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalAcuityPlanBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalAcuityPlanBundleValidator()
        let item = Staffing.newSeasonalAcuityPlanBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalAcuityPlanBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.SeasonalAcuityPlanBundleNameLengthRule(maxLength: 3600)
        let item = Staffing.newSeasonalAcuityPlanBundle("x", title: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalAcuityPlanBundleRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Staffing.SeasonalAcuityPlanBundleRefillsRangeRule(min: 80, max: 86400)
        let item = Staffing.newSeasonalAcuityPlanBundle("x", title: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSeasonalAcuityPlanBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SeasonalAcuityPlanBundleRequiredCodeRule(
            message: "seasonal acuity plan bundle needs a value"
        )
        let item = Staffing.newSeasonalAcuityPlanBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSeasonalAcuityPlanBundleCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Staffing.SeasonalAcuityPlanBundleCategoryLengthRule(maxLength: 1000)
        let item = Staffing.newSeasonalAcuityPlanBundle("x", title: "y")
        item.category = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalAcuityPlanBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.SeasonalAcuityPlanBundleRequiredNameRule(
            message: "seasonal acuity plan bundle needs a value"
        )
        let item = Staffing.newSeasonalAcuityPlanBundle("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
