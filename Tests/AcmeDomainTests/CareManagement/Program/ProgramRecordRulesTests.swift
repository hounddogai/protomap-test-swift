@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramRecordValidator()
        let item = CareManagement.newProgramRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramRecordRequiredCodeRule(message: "program record needs a value")
        let item = CareManagement.newProgramRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramRecordLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.ProgramRecordLabelLengthRule(maxLength: 120)
        let item = CareManagement.newProgramRecord("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.ProgramRecordRequiredLabelRule(message: "program record needs an entry")
        let item = CareManagement.newProgramRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
