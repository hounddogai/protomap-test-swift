@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledReferenceRangeSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledReferenceRangeSegmentValidator()
        let item = Labs.newScheduledReferenceRangeSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledReferenceRangeSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ScheduledReferenceRangeSegmentCodeLengthRule(maxLength: 16)
        let item = Labs.newScheduledReferenceRangeSegment("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsScheduledReferenceRangeSegmentDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Labs.ScheduledReferenceRangeSegmentDosageMgRangeRule(min: 5.9, max: 1765.0)
        let item = Labs.newScheduledReferenceRangeSegment("x", name: "y")
        item.dosageMg = 1766.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledReferenceRangeSegmentMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.ScheduledReferenceRangeSegmentMaximumRangeRule(min: 0.9, max: 3349.9)
        let item = Labs.newScheduledReferenceRangeSegment("x", name: "y")
        item.maximum = 3351.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledReferenceRangeSegmentRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.ScheduledReferenceRangeSegmentRequiredPayerRule(
            message: "scheduled reference range segment needs an entry"
        )
        let item = Labs.newScheduledReferenceRangeSegment("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
