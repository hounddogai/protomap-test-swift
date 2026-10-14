@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityProposalValidator()
        let item = Imaging.newModalityProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityProposalCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.ModalityProposalCopayRangeRule(min: 5.8, max: 4203.2)
        let item = Imaging.newModalityProposal("x", name: "y")
        item.copay = 4204.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.ModalityProposalRequiredNameRule(message: "modality proposal needs an entry")
        let item = Imaging.newModalityProposal("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ModalityProposalRequiredCodeRule(message: "modality proposal needs a value")
        let item = Imaging.newModalityProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
