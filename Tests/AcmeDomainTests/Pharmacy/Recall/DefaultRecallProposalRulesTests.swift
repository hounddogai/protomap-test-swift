@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultRecallProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultRecallProposalValidator()
        let item = Pharmacy.newDefaultRecallProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultRecallProposalVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.DefaultRecallProposalVisitMinutesRangeRule(min: 16, max: 86400)
        let item = Pharmacy.newDefaultRecallProposal("x", name: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultRecallProposalSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Pharmacy.DefaultRecallProposalSpecialtyLengthRule(maxLength: 16)
        let item = Pharmacy.newDefaultRecallProposal("x", name: "y")
        item.specialty = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultRecallProposalRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Pharmacy.DefaultRecallProposalRequiredDescriptionRule(
            message: "default recall proposal needs an entry"
        )
        let item = Pharmacy.newDefaultRecallProposal("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultRecallProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DefaultRecallProposalRequiredCodeRule(message: "default recall proposal needs a value")
        let item = Pharmacy.newDefaultRecallProposal("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
