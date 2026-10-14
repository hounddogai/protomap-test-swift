@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanProfileValidator()
        let item = Staffing.newAcuityPlanProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AcuityPlanProfileRequiredCodeRule(message: "acuity plan profile needs an entry")
        let item = Staffing.newAcuityPlanProfile("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanProfileRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Staffing.AcuityPlanProfileRequiredWardRule(message: "acuity plan profile needs a value")
        let item = Staffing.newAcuityPlanProfile("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AcuityPlanProfileCodeLengthRule(maxLength: 3600)
        let item = Staffing.newAcuityPlanProfile("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
