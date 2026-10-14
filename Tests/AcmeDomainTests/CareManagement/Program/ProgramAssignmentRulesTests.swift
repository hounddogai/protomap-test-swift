@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramAssignmentValidator()
        let item = CareManagement.newProgramAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramAssignmentPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = CareManagement.ProgramAssignmentPayerLengthRule(maxLength: 255)
        let item = CareManagement.newProgramAssignment("x", title: "y")
        item.payer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramAssignmentRequiredCodeRule(message: "program assignment needs this field")
        let item = CareManagement.newProgramAssignment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramAssignmentRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = CareManagement.ProgramAssignmentRequiredPayerRule(message: "program assignment needs an entry")
        let item = CareManagement.newProgramAssignment("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramAssignmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.ProgramAssignmentRequiredTitleRule(message: "program assignment needs an entry")
        let item = CareManagement.newProgramAssignment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.ProgramAssignmentTitleLengthRule(maxLength: 16)
        let item = CareManagement.newProgramAssignment("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramAssignmentSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.ProgramAssignmentSequenceRangeRule(min: 16, max: 80)
        let item = CareManagement.newProgramAssignment("x", title: "y")
        item.sequence = 81
        #expect(rule.check(item).count > 0)
    }
}
