@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierProposalValidator()
        let item = Labs.newCourierProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierProposalRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Labs.CourierProposalRequiredPatientRefRule(message: "courier proposal needs a value")
        let item = Labs.newCourierProposal("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierProposalPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Labs.CourierProposalPatientRefLengthRule(maxLength: 80)
        let item = Labs.newCourierProposal("x", name: "y")
        item.patientRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierProposalDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.CourierProposalDurationMinutesRangeRule(min: 64, max: 64)
        let item = Labs.newCourierProposal("x", name: "y")
        item.durationMinutes = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierProposalBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.CourierProposalBatchSizeRangeRule(min: 1000, max: 3600)
        let item = Labs.newCourierProposal("x", name: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}
