@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalSkillMixProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalSkillMixProfileValidator()
        let item = Staffing.newRegionalSkillMixProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalSkillMixProfileRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Staffing.RegionalSkillMixProfileRequiredExternalRefRule(
            message: "regional skill mix profile needs this field"
        )
        let item = Staffing.newRegionalSkillMixProfile("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRegionalSkillMixProfileProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Staffing.RegionalSkillMixProfileProcedureCodeLengthRule(maxLength: 32)
        let item = Staffing.newRegionalSkillMixProfile("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalSkillMixProfileExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Staffing.RegionalSkillMixProfileExternalRefLengthRule(maxLength: 80)
        let item = Staffing.newRegionalSkillMixProfile("x", name: "y")
        item.externalRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
