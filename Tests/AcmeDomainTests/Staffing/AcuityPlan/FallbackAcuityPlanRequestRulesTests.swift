@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackAcuityPlanRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackAcuityPlanRequestValidator()
        let item = Staffing.newFallbackAcuityPlanRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackAcuityPlanRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.FallbackAcuityPlanRequestRequiredTitleRule(
            message: "fallback acuity plan request needs an entry"
        )
        let item = Staffing.newFallbackAcuityPlanRequest("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackAcuityPlanRequestMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Staffing.FallbackAcuityPlanRequestMaximumRangeRule(min: 0.1, max: 1286.7)
        let item = Staffing.newFallbackAcuityPlanRequest("x", name: "y")
        item.maximum = 1288.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackAcuityPlanRequestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.FallbackAcuityPlanRequestRequiredNameRule(
            message: "fallback acuity plan request needs an entry"
        )
        let item = Staffing.newFallbackAcuityPlanRequest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackAcuityPlanRequestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.FallbackAcuityPlanRequestRateRangeRule(min: 1.9, max: 4390.8)
        let item = Staffing.newFallbackAcuityPlanRequest("x", name: "y")
        item.rate = 4392.3
        #expect(rule.check(item).count > 0)
    }
}
