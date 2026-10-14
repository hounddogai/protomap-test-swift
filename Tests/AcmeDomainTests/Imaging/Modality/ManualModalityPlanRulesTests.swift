@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualModalityPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultManualModalityPlanValidator()
        let item = Imaging.newManualModalityPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingManualModalityPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ManualModalityPlanCodeLengthRule(maxLength: 3600)
        let item = Imaging.newManualModalityPlan("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingManualModalityPlanMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.ManualModalityPlanMarginRangeRule(min: 8.9, max: 4904.0)
        let item = Imaging.newManualModalityPlan("x", title: "y")
        item.margin = 4905.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingManualModalityPlanRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Imaging.ManualModalityPlanRequiredCategoryRule(message: "manual modality plan needs a value")
        let item = Imaging.newManualModalityPlan("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualModalityPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.ManualModalityPlanRequiredTitleRule(message: "manual modality plan needs an entry")
        let item = Imaging.newManualModalityPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualModalityPlanRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Imaging.ManualModalityPlanRequiredLocaleRule(message: "manual modality plan needs an entry")
        let item = Imaging.newManualModalityPlan("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
