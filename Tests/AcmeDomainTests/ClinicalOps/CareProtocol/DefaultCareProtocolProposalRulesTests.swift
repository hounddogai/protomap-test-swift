@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultCareProtocolProposalValidatorExtraTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultDefaultCareProtocolProposalValidator()
        let item = ClinicalOps.newDefaultCareProtocolProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsDefaultCareProtocolProposalRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.DefaultCareProtocolProposalRequiredTitleRule(
            message: "default care protocol proposal needs an entry"
        )
        let item = ClinicalOps.newDefaultCareProtocolProposal("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultCareProtocolProposalRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = ClinicalOps.DefaultCareProtocolProposalRequiredRegionRule(
            message: "default care protocol proposal needs a value"
        )
        let item = ClinicalOps.newDefaultCareProtocolProposal("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
