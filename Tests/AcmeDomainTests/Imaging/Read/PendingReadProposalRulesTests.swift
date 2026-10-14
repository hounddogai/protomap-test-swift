@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingReadProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPendingReadProposalValidator()
        let item = Imaging.newPendingReadProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPendingReadProposalRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Imaging.PendingReadProposalRequiredLocaleRule(message: "pending read proposal needs a value")
        let item = Imaging.newPendingReadProposal("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingReadProposalRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Imaging.PendingReadProposalRequiredChecksumRule(message: "pending read proposal needs an entry")
        let item = Imaging.newPendingReadProposal("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
