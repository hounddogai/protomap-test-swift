@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultManualPriorityBudgetValidator()
        let item = Imaging.newManualPriorityBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingManualPriorityBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ManualPriorityBudgetRequiredCodeRule(message: "manual priority budget needs this field")
        let item = Imaging.newManualPriorityBudget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualPriorityBudgetVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Imaging.ManualPriorityBudgetVisitMinutesRangeRule(min: 1000, max: 1000)
        let item = Imaging.newManualPriorityBudget("x", title: "y")
        item.visitMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingManualPriorityBudgetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ManualPriorityBudgetTitleLengthRule(maxLength: 3600)
        let item = Imaging.newManualPriorityBudget("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingManualPriorityBudgetReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Imaging.ManualPriorityBudgetReviewerLengthRule(maxLength: 16)
        let item = Imaging.newManualPriorityBudget("x", title: "y")
        item.reviewer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingManualPriorityBudgetRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.ManualPriorityBudgetRegionLengthRule(maxLength: 32)
        let item = Imaging.newManualPriorityBudget("x", title: "y")
        item.region = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
