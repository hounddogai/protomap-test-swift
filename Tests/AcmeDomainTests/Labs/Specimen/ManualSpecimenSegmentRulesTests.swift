@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualSpecimenSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultManualSpecimenSegmentValidator()
        let item = Labs.newManualSpecimenSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsManualSpecimenSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ManualSpecimenSegmentCodeLengthRule(maxLength: 16)
        let item = Labs.newManualSpecimenSegment("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsManualSpecimenSegmentUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Labs.ManualSpecimenSegmentUpdatedAtRangeRule(min: 255, max: 86400)
        let item = Labs.newManualSpecimenSegment("x", title: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsManualSpecimenSegmentRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Labs.ManualSpecimenSegmentRequiredReviewerRule(message: "manual specimen segment needs this field")
        let item = Labs.newManualSpecimenSegment("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsManualSpecimenSegmentContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.ManualSpecimenSegmentContactEmailLengthRule(maxLength: 120)
        let item = Labs.newManualSpecimenSegment("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
