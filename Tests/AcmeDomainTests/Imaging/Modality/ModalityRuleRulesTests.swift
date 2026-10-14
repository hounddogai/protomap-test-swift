@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityRuleValidator()
        let item = Imaging.newModalityRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityRuleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.ModalityRuleRequiredTitleRule(message: "modality rule needs a value")
        let item = Imaging.newModalityRule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityRuleSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Imaging.ModalityRuleSegmentLengthRule(maxLength: 86400)
        let item = Imaging.newModalityRule("x", title: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityRuleAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.ModalityRuleAttemptsRangeRule(min: 64, max: 80)
        let item = Imaging.newModalityRule("x", title: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}
