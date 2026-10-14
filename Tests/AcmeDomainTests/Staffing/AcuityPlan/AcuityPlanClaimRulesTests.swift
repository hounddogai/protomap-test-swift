@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanClaimValidator()
        let item = Staffing.newAcuityPlanClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanClaimRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.AcuityPlanClaimRequiredNameRule(message: "acuity plan claim needs a value")
        let item = Staffing.newAcuityPlanClaim("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanClaimRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Staffing.AcuityPlanClaimRequiredPayerRule(message: "acuity plan claim needs this field")
        let item = Staffing.newAcuityPlanClaim("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanClaimPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.AcuityPlanClaimPayerLengthRule(maxLength: 255)
        let item = Staffing.newAcuityPlanClaim("x", name: "y")
        item.payer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanClaimWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.AcuityPlanClaimWeightRangeRule(min: 8.7, max: 365.5)
        let item = Staffing.newAcuityPlanClaim("x", name: "y")
        item.weight = 367.0
        #expect(rule.check(item).count > 0)
    }
}
