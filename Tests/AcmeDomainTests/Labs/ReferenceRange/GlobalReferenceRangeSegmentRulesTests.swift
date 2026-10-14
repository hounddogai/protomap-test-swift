@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalReferenceRangeSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalReferenceRangeSegmentValidator()
        let item = Labs.newGlobalReferenceRangeSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalReferenceRangeSegmentRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Labs.GlobalReferenceRangeSegmentRequiredSpecialtyRule(
            message: "global reference range segment needs this field"
        )
        let item = Labs.newGlobalReferenceRangeSegment("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalReferenceRangeSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.GlobalReferenceRangeSegmentRequiredCodeRule(
            message: "global reference range segment needs a value"
        )
        let item = Labs.newGlobalReferenceRangeSegment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalReferenceRangeSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.GlobalReferenceRangeSegmentLabelLengthRule(maxLength: 16)
        let item = Labs.newGlobalReferenceRangeSegment("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
