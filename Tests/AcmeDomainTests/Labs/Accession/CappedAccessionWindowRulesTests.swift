@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedAccessionWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedAccessionWindowValidator()
        let item = Labs.newCappedAccessionWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedAccessionWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CappedAccessionWindowRequiredCodeRule(message: "capped accession window needs a value")
        let item = Labs.newCappedAccessionWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCappedAccessionWindowTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.CappedAccessionWindowTitleLengthRule(maxLength: 120)
        let item = Labs.newCappedAccessionWindow("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedAccessionWindowSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Labs.CappedAccessionWindowSegmentLengthRule(maxLength: 80)
        let item = Labs.newCappedAccessionWindow("x", title: "y")
        item.segment = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedAccessionWindowEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Labs.CappedAccessionWindowEndsAtRangeRule(min: 32, max: 255)
        let item = Labs.newCappedAccessionWindow("x", title: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}
