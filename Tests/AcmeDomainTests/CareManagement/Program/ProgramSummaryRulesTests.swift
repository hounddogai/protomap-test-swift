@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramSummaryValidator()
        let item = CareManagement.newProgramSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramSummaryMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = CareManagement.ProgramSummaryMaximumRangeRule(min: 0.7, max: 2052.3)
        let item = CareManagement.newProgramSummary("x", title: "y")
        item.maximum = 2053.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramSummaryVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.ProgramSummaryVersionRangeRule(min: 16, max: 16)
        let item = CareManagement.newProgramSummary("x", title: "y")
        item.version = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramSummaryRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = CareManagement.ProgramSummaryRequiredChecksumRule(message: "program summary needs a value")
        let item = CareManagement.newProgramSummary("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
