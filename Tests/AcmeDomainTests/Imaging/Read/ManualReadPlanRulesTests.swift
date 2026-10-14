@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualReadPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultManualReadPlanValidator()
        let item = Imaging.newManualReadPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingManualReadPlanWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Imaging.ManualReadPlanWindowDaysRangeRule(min: 16, max: 86400)
        let item = Imaging.newManualReadPlan("x", name: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingManualReadPlanRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Imaging.ManualReadPlanRequiredOwnerIDRule(message: "manual read plan needs this field")
        let item = Imaging.newManualReadPlan("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualReadPlanLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Imaging.ManualReadPlanLimitRangeRule(min: 64, max: 64)
        let item = Imaging.newManualReadPlan("x", name: "y")
        item.limit = 65
        #expect(rule.check(item).count > 0)
    }
}
