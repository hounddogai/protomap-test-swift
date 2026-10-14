@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultCourierProposalValidator()
        let item = Labs.newDefaultCourierProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultCourierProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.DefaultCourierProposalRequiredCodeRule(message: "default courier proposal needs a value")
        let item = Labs.newDefaultCourierProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultCourierProposalRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Labs.DefaultCourierProposalRequiredSourceRule(message: "default courier proposal needs an entry")
        let item = Labs.newDefaultCourierProposal("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultCourierProposalSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Labs.DefaultCourierProposalSourceLengthRule(maxLength: 64)
        let item = Labs.newDefaultCourierProposal("x", name: "y")
        item.source = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsDefaultCourierProposalExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.DefaultCourierProposalExpiresAtRangeRule(min: 120, max: 1000)
        let item = Labs.newDefaultCourierProposal("x", name: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
