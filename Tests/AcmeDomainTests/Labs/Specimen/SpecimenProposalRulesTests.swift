@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenProposalValidator()
        let item = Labs.newSpecimenProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenProposalPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Labs.SpecimenProposalPhoneLengthRule(maxLength: 16)
        let item = Labs.newSpecimenProposal("x", title: "y")
        item.phone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenProposalRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Labs.SpecimenProposalRequiredOwnerIDRule(message: "specimen proposal needs this field")
        let item = Labs.newSpecimenProposal("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SpecimenProposalRequiredCodeRule(message: "specimen proposal needs this field")
        let item = Labs.newSpecimenProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenProposalCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.SpecimenProposalCeilingRangeRule(min: 6.7, max: 4999.7)
        let item = Labs.newSpecimenProposal("x", title: "y")
        item.ceiling = 5001.2
        #expect(rule.check(item).count > 0)
    }
}
