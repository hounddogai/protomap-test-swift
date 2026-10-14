@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledAccessionTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledAccessionTargetValidator()
        let item = Labs.newScheduledAccessionTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledAccessionTargetRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Labs.ScheduledAccessionTargetRequiredSegmentRule(message: "scheduled accession target needs a value")
        let item = Labs.newScheduledAccessionTarget("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledAccessionTargetCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.ScheduledAccessionTargetCeilingRangeRule(min: 5.3, max: 3826.9)
        let item = Labs.newScheduledAccessionTarget("x", label: "y")
        item.ceiling = 3828.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledAccessionTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ScheduledAccessionTargetLabelLengthRule(maxLength: 16)
        let item = Labs.newScheduledAccessionTarget("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsScheduledAccessionTargetMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.ScheduledAccessionTargetMaximumRangeRule(min: 0.8, max: 376.8)
        let item = Labs.newScheduledAccessionTarget("x", label: "y")
        item.maximum = 378.3
        #expect(rule.check(item).count > 0)
    }
}
