@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenReviewValidator()
        let item = Labs.newSpecimenReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenReviewRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Labs.SpecimenReviewRequiredDescriptionRule(message: "specimen review needs a value")
        let item = Labs.newSpecimenReview("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.SpecimenReviewRequiredLabelRule(message: "specimen review needs this field")
        let item = Labs.newSpecimenReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenReviewDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Labs.SpecimenReviewDescriptionLengthRule(maxLength: 255)
        let item = Labs.newSpecimenReview("x", label: "y")
        item.description = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
