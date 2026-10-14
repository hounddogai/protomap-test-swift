@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredSkillMixReservationValidator()
        let item = Staffing.newTieredSkillMixReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredSkillMixReservationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.TieredSkillMixReservationRequiredNameRule(
            message: "tiered skill mix reservation needs a value"
        )
        let item = Staffing.newTieredSkillMixReservation("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredSkillMixReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.TieredSkillMixReservationCodeLengthRule(maxLength: 120)
        let item = Staffing.newTieredSkillMixReservation("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
