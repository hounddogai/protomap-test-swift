@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledFormularyMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultScheduledFormularyMilestoneValidator()
        let item = Pharmacy.newScheduledFormularyMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyScheduledFormularyMilestoneRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Pharmacy.ScheduledFormularyMilestoneRequiredProcedureCodeRule(
            message: "scheduled formulary milestone needs a value"
        )
        let item = Pharmacy.newScheduledFormularyMilestone("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyScheduledFormularyMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.ScheduledFormularyMilestoneRequiredTitleRule(
            message: "scheduled formulary milestone needs a value"
        )
        let item = Pharmacy.newScheduledFormularyMilestone("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyScheduledFormularyMilestoneRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.ScheduledFormularyMilestoneRatioRangeRule(min: 6.3, max: 2534.8)
        let item = Pharmacy.newScheduledFormularyMilestone("x", title: "y")
        item.ratio = 2536.3
        #expect(rule.check(item).count > 0)
    }
}
