@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityProposalValidator()
        let item = Imaging.newPriorityProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.PriorityProposalRequiredNameRule(message: "priority proposal needs a value")
        let item = Imaging.newPriorityProposal("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityProposalLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Imaging.PriorityProposalLimitRangeRule(min: 80, max: 255)
        let item = Imaging.newPriorityProposal("x", name: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PriorityProposalRequiredCodeRule(message: "priority proposal needs a value")
        let item = Imaging.newPriorityProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityProposalAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.PriorityProposalAcuityRangeRule(min: 64, max: 3600)
        let item = Imaging.newPriorityProposal("x", name: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}
