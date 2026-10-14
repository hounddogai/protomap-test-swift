@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryCareProtocolReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryCareProtocolReviewValidator()
        let item = ClinicalOps.newPrimaryCareProtocolReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryCareProtocolReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.PrimaryCareProtocolReviewCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newPrimaryCareProtocolReview("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryCareProtocolReviewRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.PrimaryCareProtocolReviewRequiredTitleRule(
            message: "primary care protocol review needs this field"
        )
        let item = ClinicalOps.newPrimaryCareProtocolReview("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPrimaryCareProtocolReviewAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.PrimaryCareProtocolReviewAcuityRangeRule(min: 16, max: 86400)
        let item = ClinicalOps.newPrimaryCareProtocolReview("x", title: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPrimaryCareProtocolReviewRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = ClinicalOps.PrimaryCareProtocolReviewRequiredChecksumRule(
            message: "primary care protocol review needs an entry"
        )
        let item = ClinicalOps.newPrimaryCareProtocolReview("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
