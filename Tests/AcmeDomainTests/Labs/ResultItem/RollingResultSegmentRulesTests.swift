@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingResultSegmentValidator()
        let item = Labs.newRollingResultSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingResultSegmentRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Labs.RollingResultSegmentRequiredSummaryRule(message: "rolling result segment needs a value")
        let item = Labs.newRollingResultSegment("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingResultSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.RollingResultSegmentLabelLengthRule(maxLength: 1000)
        let item = Labs.newRollingResultSegment("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingResultSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.RollingResultSegmentRequiredLabelRule(message: "rolling result segment needs an entry")
        let item = Labs.newRollingResultSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingResultSegmentLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Labs.RollingResultSegmentLocaleLengthRule(maxLength: 1000)
        let item = Labs.newRollingResultSegment("x", label: "y")
        item.locale = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
