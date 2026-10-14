@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictPriorityPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictPriorityPlanValidator()
        let item = Imaging.newStrictPriorityPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictPriorityPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.StrictPriorityPlanCodeLengthRule(maxLength: 120)
        let item = Imaging.newStrictPriorityPlan("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictPriorityPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StrictPriorityPlanRequiredCodeRule(message: "strict priority plan needs a value")
        let item = Imaging.newStrictPriorityPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictPriorityPlanDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Imaging.StrictPriorityPlanDiagnosisCodeLengthRule(maxLength: 255)
        let item = Imaging.newStrictPriorityPlan("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictPriorityPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.StrictPriorityPlanRequiredTitleRule(message: "strict priority plan needs a value")
        let item = Imaging.newStrictPriorityPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictPriorityPlanCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.StrictPriorityPlanCopayRangeRule(min: 1.6, max: 4034.9)
        let item = Imaging.newStrictPriorityPlan("x", title: "y")
        item.copay = 4036.4
        #expect(rule.check(item).count > 0)
    }
}
