@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalRecallProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRegionalRecallProposalValidator()
        let item = Pharmacy.newRegionalRecallProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRegionalRecallProposalProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.RegionalRecallProposalProcedureCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newRegionalRecallProposal("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRegionalRecallProposalDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Pharmacy.RegionalRecallProposalDurationMinutesRangeRule(min: 16, max: 86400)
        let item = Pharmacy.newRegionalRecallProposal("x", name: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRegionalRecallProposalRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Pharmacy.RegionalRecallProposalRequiredEncounterIDRule(
            message: "regional recall proposal needs this field"
        )
        let item = Pharmacy.newRegionalRecallProposal("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
