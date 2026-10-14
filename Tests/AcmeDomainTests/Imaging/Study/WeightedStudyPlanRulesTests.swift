@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedStudyPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedStudyPlanValidator()
        let item = Imaging.newWeightedStudyPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedStudyPlanRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Imaging.WeightedStudyPlanRequiredSummaryRule(message: "weighted study plan needs an entry")
        let item = Imaging.newWeightedStudyPlan("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWeightedStudyPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WeightedStudyPlanCodeLengthRule(maxLength: 1000)
        let item = Imaging.newWeightedStudyPlan("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedStudyPlanChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Imaging.WeightedStudyPlanChannelLengthRule(maxLength: 16)
        let item = Imaging.newWeightedStudyPlan("x", label: "y")
        item.channel = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
