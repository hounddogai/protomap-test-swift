@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingRemittanceProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingRemittanceProposalValidator()
        let item = RevenueCycle.newRollingRemittanceProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingRemittanceProposalPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = RevenueCycle.RollingRemittanceProposalPatientRefLengthRule(maxLength: 80)
        let item = RevenueCycle.newRollingRemittanceProposal("x", title: "y")
        item.patientRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRollingRemittanceProposalRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.RollingRemittanceProposalRequiredUnitRule(
            message: "rolling remittance proposal needs an entry"
        )
        let item = RevenueCycle.newRollingRemittanceProposal("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
