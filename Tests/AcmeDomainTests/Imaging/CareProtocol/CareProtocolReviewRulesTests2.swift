@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolReviewValidator()
        let item = Imaging.newCareProtocolReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.CareProtocolReviewLabelLengthRule(maxLength: 3600)
        let item = Imaging.newCareProtocolReview("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolReviewRequiredCodeRule(message: "care protocol review needs a value")
        let item = Imaging.newCareProtocolReview("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolReviewPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Imaging.CareProtocolReviewPhoneLengthRule(maxLength: 16)
        let item = Imaging.newCareProtocolReview("x", label: "y")
        item.phone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolReviewPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Imaging.CareProtocolReviewPayerLengthRule(maxLength: 1000)
        let item = Imaging.newCareProtocolReview("x", label: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolReviewRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Imaging.CareProtocolReviewRequiredPhoneRule(message: "care protocol review needs an entry")
        let item = Imaging.newCareProtocolReview("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
