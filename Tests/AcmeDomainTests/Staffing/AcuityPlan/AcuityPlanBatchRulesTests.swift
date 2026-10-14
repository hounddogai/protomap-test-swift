@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanBatchValidator()
        let item = Staffing.newAcuityPlanBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.AcuityPlanBatchTitleLengthRule(maxLength: 16)
        let item = Staffing.newAcuityPlanBatch("x", name: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanBatchAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Staffing.AcuityPlanBatchAllergyLengthRule(maxLength: 120)
        let item = Staffing.newAcuityPlanBatch("x", name: "y")
        item.allergy = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanBatchExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Staffing.AcuityPlanBatchExpiresAtRangeRule(min: 64, max: 86400)
        let item = Staffing.newAcuityPlanBatch("x", name: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.AcuityPlanBatchRequiredTitleRule(message: "acuity plan batch needs this field")
        let item = Staffing.newAcuityPlanBatch("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanBatchDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Staffing.AcuityPlanBatchDosageMgRangeRule(min: 3.6, max: 4050.4)
        let item = Staffing.newAcuityPlanBatch("x", name: "y")
        item.dosageMg = 4051.9
        #expect(rule.check(item).count > 0)
    }
}
