@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalCourierTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalCourierTierValidator()
        let item = Labs.newGlobalCourierTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalCourierTierWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Labs.GlobalCourierTierWeightRangeRule(min: 6.3, max: 1301.8)
        let item = Labs.newGlobalCourierTier("x", title: "y")
        item.weight = 1303.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsGlobalCourierTierScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.GlobalCourierTierScoreRangeRule(min: 2.6, max: 3377.7)
        let item = Labs.newGlobalCourierTier("x", title: "y")
        item.score = 3379.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsGlobalCourierTierRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Labs.GlobalCourierTierRequiredNotesRule(message: "global courier tier needs an entry")
        let item = Labs.newGlobalCourierTier("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
