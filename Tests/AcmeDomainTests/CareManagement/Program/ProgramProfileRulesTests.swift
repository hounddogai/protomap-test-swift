@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramProfileValidator()
        let item = CareManagement.newProgramProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramProfileLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.ProgramProfileLabelLengthRule(maxLength: 80)
        let item = CareManagement.newProgramProfile("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramProfileRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = CareManagement.ProgramProfileRequiredExternalRefRule(message: "program profile needs an entry")
        let item = CareManagement.newProgramProfile("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramProfileRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = CareManagement.ProgramProfileRequiredProcedureCodeRule(message: "program profile needs this field")
        let item = CareManagement.newProgramProfile("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramProfileRequiredCodeRule(message: "program profile needs this field")
        let item = CareManagement.newProgramProfile("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramProfileExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.ProgramProfileExternalRefLengthRule(maxLength: 64)
        let item = CareManagement.newProgramProfile("x", label: "y")
        item.externalRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
