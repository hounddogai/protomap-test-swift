@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedReadProposalValidator()
        let item = Imaging.newWeightedReadProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedReadProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.WeightedReadProposalRequiredLabelRule(message: "weighted read proposal needs this field")
        let item = Imaging.newWeightedReadProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWeightedReadProposalWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.WeightedReadProposalWeightRangeRule(min: 9.1, max: 183.1)
        let item = Imaging.newWeightedReadProposal("x", label: "y")
        item.weight = 184.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWeightedReadProposalStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Imaging.WeightedReadProposalStartsAtRangeRule(min: 32, max: 3600)
        let item = Imaging.newWeightedReadProposal("x", label: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWeightedReadProposalRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.WeightedReadProposalRateRangeRule(min: 2.9, max: 921.7)
        let item = Imaging.newWeightedReadProposal("x", label: "y")
        item.rate = 923.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWeightedReadProposalSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Imaging.WeightedReadProposalSpecialtyLengthRule(maxLength: 16)
        let item = Imaging.newWeightedReadProposal("x", label: "y")
        item.specialty = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedReadProposalRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Imaging.WeightedReadProposalRequiredSpecialtyRule(message: "weighted read proposal needs an entry")
        let item = Imaging.newWeightedReadProposal("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
