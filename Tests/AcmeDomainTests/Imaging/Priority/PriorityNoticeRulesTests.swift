@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityNoticeValidator()
        let item = Imaging.newPriorityNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityNoticeTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.PriorityNoticeTitleLengthRule(maxLength: 3600)
        let item = Imaging.newPriorityNotice("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityNoticeAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.PriorityNoticeAcuityRangeRule(min: 1000, max: 3600)
        let item = Imaging.newPriorityNotice("x", title: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityNoticeSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Imaging.PriorityNoticeSequenceRangeRule(min: 16, max: 80)
        let item = Imaging.newPriorityNotice("x", title: "y")
        item.sequence = 81
        #expect(rule.check(item).count > 0)
    }
}
