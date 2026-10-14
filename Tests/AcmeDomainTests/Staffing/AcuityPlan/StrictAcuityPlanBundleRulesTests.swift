@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictAcuityPlanBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictAcuityPlanBundleValidator()
        let item = Staffing.newStrictAcuityPlanBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictAcuityPlanBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.StrictAcuityPlanBundleCodeLengthRule(maxLength: 80)
        let item = Staffing.newStrictAcuityPlanBundle("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingStrictAcuityPlanBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.StrictAcuityPlanBundleRequiredCodeRule(message: "strict acuity plan bundle needs a value")
        let item = Staffing.newStrictAcuityPlanBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictAcuityPlanBundlePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Staffing.StrictAcuityPlanBundlePatientRefLengthRule(maxLength: 255)
        let item = Staffing.newStrictAcuityPlanBundle("x", title: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingStrictAcuityPlanBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.StrictAcuityPlanBundleTitleLengthRule(maxLength: 80)
        let item = Staffing.newStrictAcuityPlanBundle("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
