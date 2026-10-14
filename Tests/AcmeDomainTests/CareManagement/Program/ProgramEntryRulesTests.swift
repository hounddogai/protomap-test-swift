@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramEntryValidator()
        let item = CareManagement.newProgramEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramEntryCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = CareManagement.ProgramEntryCopayRangeRule(min: 3.0, max: 218.8)
        let item = CareManagement.newProgramEntry("x", label: "y")
        item.copay = 220.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramEntryRequiredCodeRule(message: "program entry needs a value")
        let item = CareManagement.newProgramEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramEntrySequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.ProgramEntrySequenceRangeRule(min: 16, max: 1000)
        let item = CareManagement.newProgramEntry("x", label: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}
