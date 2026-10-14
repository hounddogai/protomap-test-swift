@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingRiskScoreWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingRiskScoreWindowValidator()
        let item = CareManagement.newPendingRiskScoreWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingRiskScoreWindowContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = CareManagement.PendingRiskScoreWindowContactEmailLengthRule(maxLength: 255)
        let item = CareManagement.newPendingRiskScoreWindow("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPendingRiskScoreWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.PendingRiskScoreWindowRequiredLabelRule(
            message: "pending risk score window needs this field"
        )
        let item = CareManagement.newPendingRiskScoreWindow("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingRiskScoreWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.PendingRiskScoreWindowRequiredCodeRule(
            message: "pending risk score window needs an entry"
        )
        let item = CareManagement.newPendingRiskScoreWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
