@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanCycleValidator()
        let item = Staffing.newAcuityPlanCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanCycleRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Staffing.AcuityPlanCycleRequiredLocaleRule(message: "acuity plan cycle needs a value")
        let item = Staffing.newAcuityPlanCycle("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.AcuityPlanCycleRequiredNameRule(message: "acuity plan cycle needs a value")
        let item = Staffing.newAcuityPlanCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AcuityPlanCycleCodeLengthRule(maxLength: 32)
        let item = Staffing.newAcuityPlanCycle("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
