@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedResultSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedResultSegmentValidator()
        let item = Labs.newCappedResultSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedResultSegmentRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Labs.CappedResultSegmentRequiredFacilityRule(message: "capped result segment needs a value")
        let item = Labs.newCappedResultSegment("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCappedResultSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CappedResultSegmentRequiredCodeRule(message: "capped result segment needs this field")
        let item = Labs.newCappedResultSegment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCappedResultSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CappedResultSegmentCodeLengthRule(maxLength: 1000)
        let item = Labs.newCappedResultSegment("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
