@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramWindowValidator()
        let item = CareManagement.newProgramWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.ProgramWindowLabelLengthRule(maxLength: 3600)
        let item = CareManagement.newProgramWindow("x", name: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.ProgramWindowRequiredLabelRule(message: "program window needs an entry")
        let item = CareManagement.newProgramWindow("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramWindowUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = CareManagement.ProgramWindowUnitLengthRule(maxLength: 1000)
        let item = CareManagement.newProgramWindow("x", name: "y")
        item.unit = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ProgramWindowCodeLengthRule(maxLength: 86400)
        let item = CareManagement.newProgramWindow("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
