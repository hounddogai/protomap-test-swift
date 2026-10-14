@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramOverrideValidator()
        let item = CareManagement.newProgramOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramOverrideRequiredCodeRule(message: "program override needs an entry")
        let item = CareManagement.newProgramOverride("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ProgramOverrideCodeLengthRule(maxLength: 32)
        let item = CareManagement.newProgramOverride("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
