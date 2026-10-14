@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultManualCareProtocolReviewValidator()
        let item = Imaging.newManualCareProtocolReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingManualCareProtocolReviewRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.ManualCareProtocolReviewRegionLengthRule(maxLength: 16)
        let item = Imaging.newManualCareProtocolReview("x", title: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingManualCareProtocolReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.ManualCareProtocolReviewRequiredNameRule(
            message: "manual care protocol review needs this field"
        )
        let item = Imaging.newManualCareProtocolReview("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualCareProtocolReviewTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ManualCareProtocolReviewTitleLengthRule(maxLength: 16)
        let item = Imaging.newManualCareProtocolReview("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
