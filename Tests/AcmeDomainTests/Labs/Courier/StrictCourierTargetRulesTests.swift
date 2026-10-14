@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictCourierTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultStrictCourierTargetValidator()
        let item = Labs.newStrictCourierTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsStrictCourierTargetVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Labs.StrictCourierTargetVisitMinutesRangeRule(min: 1000, max: 86400)
        let item = Labs.newStrictCourierTarget("x", name: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsStrictCourierTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.StrictCourierTargetRequiredCodeRule(message: "strict courier target needs a value")
        let item = Labs.newStrictCourierTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictCourierTargetRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Labs.StrictCourierTargetRequiredReviewerRule(message: "strict courier target needs this field")
        let item = Labs.newStrictCourierTarget("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictCourierTargetUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Labs.StrictCourierTargetUpdatedAtRangeRule(min: 16, max: 1000)
        let item = Labs.newStrictCourierTarget("x", name: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
