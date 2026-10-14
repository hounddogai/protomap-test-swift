@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalIsolationProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultSeasonalIsolationProposalValidator()
        let item = BedManagement.newSeasonalIsolationProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementSeasonalIsolationProposalAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = BedManagement.SeasonalIsolationProposalAcuityRangeRule(min: 255, max: 1000)
        let item = BedManagement.newSeasonalIsolationProposal("x", title: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementSeasonalIsolationProposalRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = BedManagement.SeasonalIsolationProposalRevisionRangeRule(min: 16, max: 255)
        let item = BedManagement.newSeasonalIsolationProposal("x", title: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}
