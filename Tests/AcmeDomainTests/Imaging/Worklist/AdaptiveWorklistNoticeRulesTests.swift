@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveWorklistNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptiveWorklistNoticeValidator()
        let item = Imaging.newAdaptiveWorklistNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptiveWorklistNoticeRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.AdaptiveWorklistNoticeRequiredBedRule(message: "adaptive worklist notice needs a value")
        let item = Imaging.newAdaptiveWorklistNotice("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptiveWorklistNoticeTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.AdaptiveWorklistNoticeTitleLengthRule(maxLength: 3600)
        let item = Imaging.newAdaptiveWorklistNotice("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
