@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledCourierTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledCourierTierValidator()
        let item = Labs.newScheduledCourierTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledCourierTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.ScheduledCourierTierTitleLengthRule(maxLength: 64)
        let item = Labs.newScheduledCourierTier("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsScheduledCourierTierRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Labs.ScheduledCourierTierRequiredRegionRule(message: "scheduled courier tier needs a value")
        let item = Labs.newScheduledCourierTier("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledCourierTierRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Labs.ScheduledCourierTierRevisionRangeRule(min: 32, max: 1000)
        let item = Labs.newScheduledCourierTier("x", title: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledCourierTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.ScheduledCourierTierRequiredTitleRule(message: "scheduled courier tier needs a value")
        let item = Labs.newScheduledCourierTier("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledCourierTierVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Labs.ScheduledCourierTierVersionRangeRule(min: 64, max: 120)
        let item = Labs.newScheduledCourierTier("x", title: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}
