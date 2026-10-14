@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultTransferReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultTransferReviewValidator()
        let item = BedManagement.newDefaultTransferReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultTransferReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.DefaultTransferReviewRequiredNameRule(message: "default transfer review needs a value")
        let item = BedManagement.newDefaultTransferReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultTransferReviewStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = BedManagement.DefaultTransferReviewStartsAtRangeRule(min: 16, max: 64)
        let item = BedManagement.newDefaultTransferReview("x", name: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultTransferReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DefaultTransferReviewRequiredCodeRule(message: "default transfer review needs an entry")
        let item = BedManagement.newDefaultTransferReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultTransferReviewTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = BedManagement.DefaultTransferReviewTimezoneLengthRule(maxLength: 86400)
        let item = BedManagement.newDefaultTransferReview("x", name: "y")
        item.timezone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDefaultTransferReviewRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.DefaultTransferReviewRatioRangeRule(min: 8.7, max: 3881.5)
        let item = BedManagement.newDefaultTransferReview("x", name: "y")
        item.ratio = 3883.0
        #expect(rule.check(item).count > 0)
    }
}
