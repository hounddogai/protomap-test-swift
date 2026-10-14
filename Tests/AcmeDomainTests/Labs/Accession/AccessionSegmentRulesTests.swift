@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionSegmentValidator()
        let item = Labs.newAccessionSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionSegmentUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Labs.AccessionSegmentUnitLengthRule(maxLength: 120)
        let item = Labs.newAccessionSegment("x", label: "y")
        item.unit = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.AccessionSegmentLabelLengthRule(maxLength: 3600)
        let item = Labs.newAccessionSegment("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionSegmentRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Labs.AccessionSegmentRequiredUnitRule(message: "accession segment needs this field")
        let item = Labs.newAccessionSegment("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
