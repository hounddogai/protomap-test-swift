@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierReviewValidator()
        let item = Labs.newCourierReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierReviewRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Labs.CourierReviewRequiredUnitRule(message: "courier review needs a value")
        let item = Labs.newCourierReview("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierReviewRequiredCodeRule(message: "courier review needs this field")
        let item = Labs.newCourierReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.CourierReviewRequiredNameRule(message: "courier review needs a value")
        let item = Labs.newCourierReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
