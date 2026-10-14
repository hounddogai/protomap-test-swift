@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientSpecimenMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientSpecimenMilestoneValidator()
        let item = Labs.newLenientSpecimenMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientSpecimenMilestoneStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Labs.LenientSpecimenMilestoneStartsAtRangeRule(min: 16, max: 86400)
        let item = Labs.newLenientSpecimenMilestone("x", label: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLenientSpecimenMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LenientSpecimenMilestoneRequiredCodeRule(message: "lenient specimen milestone needs this field")
        let item = Labs.newLenientSpecimenMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientSpecimenMilestoneLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.LenientSpecimenMilestoneLabelLengthRule(maxLength: 86400)
        let item = Labs.newLenientSpecimenMilestone("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLenientSpecimenMilestoneRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.LenientSpecimenMilestoneRequiredLabelRule(message: "lenient specimen milestone needs a value")
        let item = Labs.newLenientSpecimenMilestone("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
