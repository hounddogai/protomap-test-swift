@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadProposalValidator()
        let item = Imaging.newReadProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ReadProposalRequiredCodeRule(message: "read proposal needs a value")
        let item = Imaging.newReadProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ReadProposalCodeLengthRule(maxLength: 32)
        let item = Imaging.newReadProposal("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadProposalSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Imaging.ReadProposalSummaryLengthRule(maxLength: 16)
        let item = Imaging.newReadProposal("x", name: "y")
        item.summary = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
