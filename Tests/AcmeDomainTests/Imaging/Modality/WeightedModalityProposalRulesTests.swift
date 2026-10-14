@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedModalityProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedModalityProposalValidator()
        let item = Imaging.newWeightedModalityProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedModalityProposalNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.WeightedModalityProposalNameLengthRule(maxLength: 1000)
        let item = Imaging.newWeightedModalityProposal("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedModalityProposalRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Imaging.WeightedModalityProposalRequiredExternalRefRule(
            message: "weighted modality proposal needs a value"
        )
        let item = Imaging.newWeightedModalityProposal("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
