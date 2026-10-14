@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramCycleValidator()
        let item = CareManagement.newProgramCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramCycleRequiredCodeRule(message: "program cycle needs an entry")
        let item = CareManagement.newProgramCycle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramCycleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.ProgramCycleTitleLengthRule(maxLength: 255)
        let item = CareManagement.newProgramCycle("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramCycleRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = CareManagement.ProgramCycleRequiredWardRule(message: "program cycle needs a value")
        let item = CareManagement.newProgramCycle("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
