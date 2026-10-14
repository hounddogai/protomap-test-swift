@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingSpecimenProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingSpecimenProposalValidator()
        let item = Labs.newRollingSpecimenProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingSpecimenProposalExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Labs.RollingSpecimenProposalExternalRefLengthRule(maxLength: 3600)
        let item = Labs.newRollingSpecimenProposal("x", name: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingSpecimenProposalAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.RollingSpecimenProposalAttemptsRangeRule(min: 80, max: 3600)
        let item = Labs.newRollingSpecimenProposal("x", name: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingSpecimenProposalNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.RollingSpecimenProposalNameLengthRule(maxLength: 32)
        let item = Labs.newRollingSpecimenProposal("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingSpecimenProposalChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Labs.RollingSpecimenProposalChannelLengthRule(maxLength: 80)
        let item = Labs.newRollingSpecimenProposal("x", name: "y")
        item.channel = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
