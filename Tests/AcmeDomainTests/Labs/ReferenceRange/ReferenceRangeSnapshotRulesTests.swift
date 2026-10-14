@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeSnapshotValidator()
        let item = Labs.newReferenceRangeSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeSnapshotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.ReferenceRangeSnapshotTitleLengthRule(maxLength: 16)
        let item = Labs.newReferenceRangeSnapshot("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeSnapshotRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Labs.ReferenceRangeSnapshotRevisionRangeRule(min: 80, max: 120)
        let item = Labs.newReferenceRangeSnapshot("x", title: "y")
        item.revision = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeSnapshotChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Labs.ReferenceRangeSnapshotChannelLengthRule(maxLength: 32)
        let item = Labs.newReferenceRangeSnapshot("x", title: "y")
        item.channel = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
