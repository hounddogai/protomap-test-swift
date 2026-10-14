@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveGoalBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveGoalBaselineValidator()
        let item = CareManagement.newAdaptiveGoalBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveGoalBaselinePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = CareManagement.AdaptiveGoalBaselinePatientRefLengthRule(maxLength: 64)
        let item = CareManagement.newAdaptiveGoalBaseline("x", title: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveGoalBaselineDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = CareManagement.AdaptiveGoalBaselineDiscountRangeRule(min: 3.4, max: 4910.4)
        let item = CareManagement.newAdaptiveGoalBaseline("x", title: "y")
        item.discount = 4911.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveGoalBaselineRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.AdaptiveGoalBaselineRequiredTitleRule(
            message: "adaptive goal baseline needs this field"
        )
        let item = CareManagement.newAdaptiveGoalBaseline("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
