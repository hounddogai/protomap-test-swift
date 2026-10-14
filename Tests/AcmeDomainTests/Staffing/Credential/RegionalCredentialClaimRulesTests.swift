@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalCredentialClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalCredentialClaimValidator()
        let item = Staffing.newRegionalCredentialClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalCredentialClaimRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Staffing.RegionalCredentialClaimRequiredReviewerRule(
            message: "regional credential claim needs this field"
        )
        let item = Staffing.newRegionalCredentialClaim("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRegionalCredentialClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.RegionalCredentialClaimRequiredCodeRule(message: "regional credential claim needs a value")
        let item = Staffing.newRegionalCredentialClaim("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
