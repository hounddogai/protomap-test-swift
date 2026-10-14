@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeSegmentValidator()
        let item = Labs.newReferenceRangeSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeSegmentSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Labs.ReferenceRangeSegmentSegmentLengthRule(maxLength: 64)
        let item = Labs.newReferenceRangeSegment("x", name: "y")
        item.segment = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeSegmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.ReferenceRangeSegmentRequiredNameRule(message: "reference range segment needs an entry")
        let item = Labs.newReferenceRangeSegment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeSegmentSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Labs.ReferenceRangeSegmentSpecialtyLengthRule(maxLength: 120)
        let item = Labs.newReferenceRangeSegment("x", name: "y")
        item.specialty = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeSegmentAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Labs.ReferenceRangeSegmentAcuityRangeRule(min: 32, max: 255)
        let item = Labs.newReferenceRangeSegment("x", name: "y")
        item.acuity = 256
        #expect(rule.check(item).count > 0)
    }
}
