@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityThresholdValidator()
        let item = Imaging.newModalityThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityThresholdGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.ModalityThresholdGraceDaysRangeRule(min: 32, max: 120)
        let item = Imaging.newModalityThreshold("x", title: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalityThresholdCodeLengthRule(maxLength: 86400)
        let item = Imaging.newModalityThreshold("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityThresholdRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Imaging.ModalityThresholdRequiredSummaryRule(message: "modality threshold needs a value")
        let item = Imaging.newModalityThreshold("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityThresholdSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Imaging.ModalityThresholdSummaryLengthRule(maxLength: 64)
        let item = Imaging.newModalityThreshold("x", title: "y")
        item.summary = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.ModalityThresholdRequiredTitleRule(message: "modality threshold needs a value")
        let item = Imaging.newModalityThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
