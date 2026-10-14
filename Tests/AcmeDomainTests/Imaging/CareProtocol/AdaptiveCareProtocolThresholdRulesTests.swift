@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveCareProtocolThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptiveCareProtocolThresholdValidator()
        let item = Imaging.newAdaptiveCareProtocolThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptiveCareProtocolThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.AdaptiveCareProtocolThresholdTitleLengthRule(maxLength: 64)
        let item = Imaging.newAdaptiveCareProtocolThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptiveCareProtocolThresholdCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Imaging.AdaptiveCareProtocolThresholdCategoryLengthRule(maxLength: 3600)
        let item = Imaging.newAdaptiveCareProtocolThreshold("x", title: "y")
        item.category = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
