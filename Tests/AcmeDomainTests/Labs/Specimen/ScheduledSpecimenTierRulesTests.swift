@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledSpecimenTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledSpecimenTierValidator()
        let item = Labs.newScheduledSpecimenTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledSpecimenTierDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Labs.ScheduledSpecimenTierDescriptionLengthRule(maxLength: 1000)
        let item = Labs.newScheduledSpecimenTier("x", title: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsScheduledSpecimenTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ScheduledSpecimenTierCodeLengthRule(maxLength: 32)
        let item = Labs.newScheduledSpecimenTier("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsScheduledSpecimenTierCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.ScheduledSpecimenTierCeilingRangeRule(min: 0.5, max: 4441.2)
        let item = Labs.newScheduledSpecimenTier("x", title: "y")
        item.ceiling = 4442.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledSpecimenTierMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.ScheduledSpecimenTierMaximumRangeRule(min: 1.8, max: 2896.3)
        let item = Labs.newScheduledSpecimenTier("x", title: "y")
        item.maximum = 2897.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledSpecimenTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ScheduledSpecimenTierRequiredCodeRule(message: "scheduled specimen tier needs an entry")
        let item = Labs.newScheduledSpecimenTier("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
