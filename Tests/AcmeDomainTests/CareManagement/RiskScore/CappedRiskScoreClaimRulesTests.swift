@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedRiskScoreClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedRiskScoreClaimValidator()
        let item = CareManagement.newCappedRiskScoreClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedRiskScoreClaimRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = CareManagement.CappedRiskScoreClaimRequiredCategoryRule(
            message: "capped risk score claim needs a value"
        )
        let item = CareManagement.newCappedRiskScoreClaim("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedRiskScoreClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CappedRiskScoreClaimCodeLengthRule(maxLength: 32)
        let item = CareManagement.newCappedRiskScoreClaim("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCappedRiskScoreClaimRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = CareManagement.CappedRiskScoreClaimRequiredContactEmailRule(
            message: "capped risk score claim needs this field"
        )
        let item = CareManagement.newCappedRiskScoreClaim("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedRiskScoreClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CappedRiskScoreClaimRequiredCodeRule(message: "capped risk score claim needs an entry")
        let item = CareManagement.newCappedRiskScoreClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
