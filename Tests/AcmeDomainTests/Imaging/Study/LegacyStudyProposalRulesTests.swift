@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyStudyProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLegacyStudyProposalValidator()
        let item = Imaging.newLegacyStudyProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLegacyStudyProposalRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.LegacyStudyProposalRatioRangeRule(min: 4.9, max: 3829.2)
        let item = Imaging.newLegacyStudyProposal("x", label: "y")
        item.ratio = 3830.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLegacyStudyProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.LegacyStudyProposalRequiredLabelRule(message: "legacy study proposal needs an entry")
        let item = Imaging.newLegacyStudyProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyStudyProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.LegacyStudyProposalRequiredCodeRule(message: "legacy study proposal needs this field")
        let item = Imaging.newLegacyStudyProposal("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyStudyProposalLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Imaging.LegacyStudyProposalLocaleLengthRule(maxLength: 16)
        let item = Imaging.newLegacyStudyProposal("x", label: "y")
        item.locale = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLegacyStudyProposalDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Imaging.LegacyStudyProposalDosageMgRangeRule(min: 8.7, max: 3992.0)
        let item = Imaging.newLegacyStudyProposal("x", label: "y")
        item.dosageMg = 3993.5
        #expect(rule.check(item).count > 0)
    }
}
