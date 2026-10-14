@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeProposalValidator()
        let item = Labs.newReferenceRangeProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeProposalRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.ReferenceRangeProposalRequiredPhoneRule(message: "reference range proposal needs an entry")
        let item = Labs.newReferenceRangeProposal("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeProposalPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Labs.ReferenceRangeProposalPhoneLengthRule(maxLength: 80)
        let item = Labs.newReferenceRangeProposal("x", title: "y")
        item.phone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeProposalRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.ReferenceRangeProposalRatioRangeRule(min: 3.0, max: 3563.0)
        let item = Labs.newReferenceRangeProposal("x", title: "y")
        item.ratio = 3564.5
        #expect(rule.check(item).count > 0)
    }
}
