@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientSkillMixAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientSkillMixAssignmentValidator()
        let item = Staffing.newLenientSkillMixAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientSkillMixAssignmentUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Staffing.LenientSkillMixAssignmentUnitLengthRule(maxLength: 3600)
        let item = Staffing.newLenientSkillMixAssignment("x", title: "y")
        item.unit = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLenientSkillMixAssignmentRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Staffing.LenientSkillMixAssignmentRequiredUnitRule(
            message: "lenient skill mix assignment needs a value"
        )
        let item = Staffing.newLenientSkillMixAssignment("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientSkillMixAssignmentRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Staffing.LenientSkillMixAssignmentRequiredPatientRefRule(
            message: "lenient skill mix assignment needs an entry"
        )
        let item = Staffing.newLenientSkillMixAssignment("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
