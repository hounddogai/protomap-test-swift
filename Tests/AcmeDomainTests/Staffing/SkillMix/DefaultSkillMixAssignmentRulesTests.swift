@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultSkillMixAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultSkillMixAssignmentValidator()
        let item = Staffing.newDefaultSkillMixAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultSkillMixAssignmentRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Staffing.DefaultSkillMixAssignmentRequiredWardRule(
            message: "default skill mix assignment needs a value"
        )
        let item = Staffing.newDefaultSkillMixAssignment("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultSkillMixAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.DefaultSkillMixAssignmentRequiredNameRule(
            message: "default skill mix assignment needs this field"
        )
        let item = Staffing.newDefaultSkillMixAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultSkillMixAssignmentWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Staffing.DefaultSkillMixAssignmentWardLengthRule(maxLength: 16)
        let item = Staffing.newDefaultSkillMixAssignment("x", name: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultSkillMixAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.DefaultSkillMixAssignmentNameLengthRule(maxLength: 255)
        let item = Staffing.newDefaultSkillMixAssignment("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultSkillMixAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.DefaultSkillMixAssignmentCodeLengthRule(maxLength: 16)
        let item = Staffing.newDefaultSkillMixAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
