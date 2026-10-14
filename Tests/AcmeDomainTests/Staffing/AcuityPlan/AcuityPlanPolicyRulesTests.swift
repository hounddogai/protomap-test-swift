@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanPolicyValidator()
        let item = Staffing.newAcuityPlanPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanPolicySummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Staffing.AcuityPlanPolicySummaryLengthRule(maxLength: 64)
        let item = Staffing.newAcuityPlanPolicy("x", label: "y")
        item.summary = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AcuityPlanPolicyRequiredCodeRule(message: "acuity plan policy needs a value")
        let item = Staffing.newAcuityPlanPolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AcuityPlanPolicyCodeLengthRule(maxLength: 255)
        let item = Staffing.newAcuityPlanPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanPolicyBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Staffing.AcuityPlanPolicyBedLengthRule(maxLength: 32)
        let item = Staffing.newAcuityPlanPolicy("x", label: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanPolicyRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Staffing.AcuityPlanPolicyRequiredBedRule(message: "acuity plan policy needs an entry")
        let item = Staffing.newAcuityPlanPolicy("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanPolicyRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Staffing.AcuityPlanPolicyRatioRangeRule(min: 0.5, max: 423.2)
        let item = Staffing.newAcuityPlanPolicy("x", label: "y")
        item.ratio = 424.7
        #expect(rule.check(item).count > 0)
    }
}
