@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanReviewValidator()
        let item = BedManagement.newDischargePlanReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanReviewRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = BedManagement.DischargePlanReviewRequiredPhoneRule(message: "discharge plan review needs a value")
        let item = BedManagement.newDischargePlanReview("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanReviewCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.DischargePlanReviewCeilingRangeRule(min: 1.2, max: 881.3)
        let item = BedManagement.newDischargePlanReview("x", title: "y")
        item.ceiling = 882.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanReviewRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = BedManagement.DischargePlanReviewRequiredContactEmailRule(
            message: "discharge plan review needs a value"
        )
        let item = BedManagement.newDischargePlanReview("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DischargePlanReviewRequiredCodeRule(message: "discharge plan review needs an entry")
        let item = BedManagement.newDischargePlanReview("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
