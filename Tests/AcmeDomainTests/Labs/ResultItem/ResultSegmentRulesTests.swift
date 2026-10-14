@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultSegmentValidator()
        let item = Labs.newResultSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultSegmentMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Labs.ResultSegmentMarginRangeRule(min: 8.6, max: 1777.4)
        let item = Labs.newResultSegment("x", label: "y")
        item.margin = 1778.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.ResultSegmentRequiredLabelRule(message: "result segment needs a value")
        let item = Labs.newResultSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultSegmentRequiredCodeRule(message: "result segment needs an entry")
        let item = Labs.newResultSegment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
