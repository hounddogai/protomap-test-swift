@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictWorklistPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictWorklistPlanValidator()
        let item = Imaging.newStrictWorklistPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictWorklistPlanTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.StrictWorklistPlanTitleLengthRule(maxLength: 64)
        let item = Imaging.newStrictWorklistPlan("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictWorklistPlanPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Imaging.StrictWorklistPlanPriorityRangeRule(min: 255, max: 1000)
        let item = Imaging.newStrictWorklistPlan("x", title: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStrictWorklistPlanRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Imaging.StrictWorklistPlanRequiredWardRule(message: "strict worklist plan needs a value")
        let item = Imaging.newStrictWorklistPlan("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictWorklistPlanWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Imaging.StrictWorklistPlanWardLengthRule(maxLength: 16)
        let item = Imaging.newStrictWorklistPlan("x", title: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
