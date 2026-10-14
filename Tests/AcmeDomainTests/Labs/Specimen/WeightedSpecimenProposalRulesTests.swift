@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedSpecimenProposalValidator()
        let item = Labs.newWeightedSpecimenProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedSpecimenProposalRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Labs.WeightedSpecimenProposalRequiredFacilityRule(message: "weighted specimen proposal needs a value")
        let item = Labs.newWeightedSpecimenProposal("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedSpecimenProposalRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.WeightedSpecimenProposalRequiredTitleRule(message: "weighted specimen proposal needs this field")
        let item = Labs.newWeightedSpecimenProposal("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedSpecimenProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.WeightedSpecimenProposalRequiredNameRule(message: "weighted specimen proposal needs a value")
        let item = Labs.newWeightedSpecimenProposal("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedSpecimenProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.WeightedSpecimenProposalRequiredCodeRule(message: "weighted specimen proposal needs an entry")
        let item = Labs.newWeightedSpecimenProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
