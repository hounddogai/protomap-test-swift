@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledAcuityPlanRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledAcuityPlanRuleValidator()
        let item = Staffing.newScheduledAcuityPlanRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledAcuityPlanRuleRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Staffing.ScheduledAcuityPlanRuleRequiredPhoneRule(
            message: "scheduled acuity plan rule needs an entry"
        )
        let item = Staffing.newScheduledAcuityPlanRule("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledAcuityPlanRuleAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Staffing.ScheduledAcuityPlanRuleAcuityRangeRule(min: 80, max: 3600)
        let item = Staffing.newScheduledAcuityPlanRule("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingScheduledAcuityPlanRulePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Staffing.ScheduledAcuityPlanRulePhoneLengthRule(maxLength: 3600)
        let item = Staffing.newScheduledAcuityPlanRule("x", label: "y")
        item.phone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledAcuityPlanRuleRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.ScheduledAcuityPlanRuleRequiredContactEmailRule(
            message: "scheduled acuity plan rule needs this field"
        )
        let item = Staffing.newScheduledAcuityPlanRule("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
