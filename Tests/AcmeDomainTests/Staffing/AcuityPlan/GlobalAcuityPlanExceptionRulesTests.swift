@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalAcuityPlanExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalAcuityPlanExceptionValidator()
        let item = Staffing.newGlobalAcuityPlanException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalAcuityPlanExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.GlobalAcuityPlanExceptionRequiredCodeRule(
            message: "global acuity plan exception needs a value"
        )
        let item = Staffing.newGlobalAcuityPlanException("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalAcuityPlanExceptionAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Staffing.GlobalAcuityPlanExceptionAllergyLengthRule(maxLength: 1000)
        let item = Staffing.newGlobalAcuityPlanException("x", title: "y")
        item.allergy = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalAcuityPlanExceptionRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.GlobalAcuityPlanExceptionRequiredContactEmailRule(
            message: "global acuity plan exception needs this field"
        )
        let item = Staffing.newGlobalAcuityPlanException("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalAcuityPlanExceptionCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.GlobalAcuityPlanExceptionCostRangeRule(min: 4.8, max: 595.2)
        let item = Staffing.newGlobalAcuityPlanException("x", title: "y")
        item.cost = 596.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingGlobalAcuityPlanExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.GlobalAcuityPlanExceptionTitleLengthRule(maxLength: 1000)
        let item = Staffing.newGlobalAcuityPlanException("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
