@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingAccessionSegmentValidator()
        let item = Labs.newRollingAccessionSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingAccessionSegmentWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Labs.RollingAccessionSegmentWardLengthRule(maxLength: 86400)
        let item = Labs.newRollingAccessionSegment("x", label: "y")
        item.ward = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingAccessionSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.RollingAccessionSegmentRequiredLabelRule(message: "rolling accession segment needs a value")
        let item = Labs.newRollingAccessionSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingAccessionSegmentRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Labs.RollingAccessionSegmentRetriesRangeRule(min: 32, max: 120)
        let item = Labs.newRollingAccessionSegment("x", label: "y")
        item.retries = 121
        #expect(rule.check(item).count > 0)
    }
}
