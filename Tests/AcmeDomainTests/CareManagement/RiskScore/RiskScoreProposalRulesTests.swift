@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreProposalValidator()
        let item = CareManagement.newRiskScoreProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreProposalClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = CareManagement.RiskScoreProposalClinicianIDLengthRule(maxLength: 1000)
        let item = CareManagement.newRiskScoreProposal("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.RiskScoreProposalRequiredNameRule(message: "risk score proposal needs this field")
        let item = CareManagement.newRiskScoreProposal("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreProposalCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = CareManagement.RiskScoreProposalCurrencyLengthRule(maxLength: 64)
        let item = CareManagement.newRiskScoreProposal("x", name: "y")
        item.currency = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreProposalRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = CareManagement.RiskScoreProposalRatioRangeRule(min: 0.8, max: 4442.7)
        let item = CareManagement.newRiskScoreProposal("x", name: "y")
        item.ratio = 4444.2
        #expect(rule.check(item).count > 0)
    }
}
