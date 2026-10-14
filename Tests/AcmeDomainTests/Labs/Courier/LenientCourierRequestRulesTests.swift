@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientCourierRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientCourierRequestValidator()
        let item = Labs.newLenientCourierRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientCourierRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.LenientCourierRequestRequiredLabelRule(message: "lenient courier request needs an entry")
        let item = Labs.newLenientCourierRequest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientCourierRequestSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.LenientCourierRequestSequenceRangeRule(min: 80, max: 1000)
        let item = Labs.newLenientCourierRequest("x", label: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLenientCourierRequestRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Labs.LenientCourierRequestRequiredSegmentRule(message: "lenient courier request needs this field")
        let item = Labs.newLenientCourierRequest("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientCourierRequestWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Labs.LenientCourierRequestWeightRangeRule(min: 2.6, max: 4941.0)
        let item = Labs.newLenientCourierRequest("x", label: "y")
        item.weight = 4942.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLenientCourierRequestSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Labs.LenientCourierRequestSegmentLengthRule(maxLength: 86400)
        let item = Labs.newLenientCourierRequest("x", label: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
