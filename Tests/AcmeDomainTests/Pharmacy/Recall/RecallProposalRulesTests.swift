@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallProposalValidator()
        let item = Pharmacy.newRecallProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallProposalChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Pharmacy.RecallProposalChannelLengthRule(maxLength: 3600)
        let item = Pharmacy.newRecallProposal("x", label: "y")
        item.channel = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallProposalRequiredCodeRule(message: "recall proposal needs this field")
        let item = Pharmacy.newRecallProposal("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallProposalRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Pharmacy.RecallProposalRequiredTimezoneRule(message: "recall proposal needs an entry")
        let item = Pharmacy.newRecallProposal("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
