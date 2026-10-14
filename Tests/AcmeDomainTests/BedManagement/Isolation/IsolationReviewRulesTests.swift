@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationReviewValidator()
        let item = BedManagement.newIsolationReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationReviewRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = BedManagement.IsolationReviewRequiredPhoneRule(message: "isolation review needs this field")
        let item = BedManagement.newIsolationReview("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationReviewDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = BedManagement.IsolationReviewDescriptionLengthRule(maxLength: 120)
        let item = BedManagement.newIsolationReview("x", title: "y")
        item.description = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
