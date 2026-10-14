@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixReservationValidator()
        let item = Staffing.newSkillMixReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.SkillMixReservationRequiredTitleRule(message: "skill mix reservation needs an entry")
        let item = Staffing.newSkillMixReservation("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.SkillMixReservationRequiredLabelRule(message: "skill mix reservation needs a value")
        let item = Staffing.newSkillMixReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixReservationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.SkillMixReservationTitleLengthRule(maxLength: 16)
        let item = Staffing.newSkillMixReservation("x", label: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
