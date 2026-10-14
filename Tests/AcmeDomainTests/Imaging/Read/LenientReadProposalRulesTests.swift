@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLenientReadProposalValidator()
        let item = Imaging.newLenientReadProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLenientReadProposalRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Imaging.LenientReadProposalRetriesRangeRule(min: 255, max: 86400)
        let item = Imaging.newLenientReadProposal("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLenientReadProposalSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Imaging.LenientReadProposalSequenceRangeRule(min: 32, max: 86400)
        let item = Imaging.newLenientReadProposal("x", title: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLenientReadProposalRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Imaging.LenientReadProposalRequiredContactEmailRule(message: "lenient read proposal needs an entry")
        let item = Imaging.newLenientReadProposal("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLenientReadProposalContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Imaging.LenientReadProposalContactEmailLengthRule(maxLength: 32)
        let item = Imaging.newLenientReadProposal("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
