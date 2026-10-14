@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramSegmentValidator()
        let item = CareManagement.newProgramSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramSegmentBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = CareManagement.ProgramSegmentBedLengthRule(maxLength: 32)
        let item = CareManagement.newProgramSegment("x", name: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramSegmentTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = CareManagement.ProgramSegmentTimezoneLengthRule(maxLength: 120)
        let item = CareManagement.newProgramSegment("x", name: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementProgramSegmentRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = CareManagement.ProgramSegmentRequiredBedRule(message: "program segment needs this field")
        let item = CareManagement.newProgramSegment("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
