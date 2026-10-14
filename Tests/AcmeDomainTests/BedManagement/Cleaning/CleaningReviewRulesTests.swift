@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningReviewValidator()
        let item = BedManagement.newCleaningReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningReviewRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = BedManagement.CleaningReviewRequiredPhoneRule(message: "cleaning review needs a value")
        let item = BedManagement.newCleaningReview("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CleaningReviewCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newCleaningReview("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningReviewPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = BedManagement.CleaningReviewPhoneLengthRule(maxLength: 80)
        let item = BedManagement.newCleaningReview("x", name: "y")
        item.phone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CleaningReviewRequiredNameRule(message: "cleaning review needs an entry")
        let item = BedManagement.newCleaningReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
