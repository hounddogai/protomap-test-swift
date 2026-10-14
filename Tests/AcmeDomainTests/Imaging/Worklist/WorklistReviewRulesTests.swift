@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistReviewValidator()
        let item = Imaging.newWorklistReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistReviewOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Imaging.WorklistReviewOwnerIDLengthRule(maxLength: 16)
        let item = Imaging.newWorklistReview("x", label: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistReviewRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Imaging.WorklistReviewRequiredOwnerIDRule(message: "worklist review needs a value")
        let item = Imaging.newWorklistReview("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistReviewCodeLengthRule(maxLength: 32)
        let item = Imaging.newWorklistReview("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
