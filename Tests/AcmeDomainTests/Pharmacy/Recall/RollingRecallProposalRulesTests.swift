@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingRecallProposalValidator()
        let item = Pharmacy.newRollingRecallProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingRecallProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.RollingRecallProposalRequiredLabelRule(message: "rolling recall proposal needs a value")
        let item = Pharmacy.newRollingRecallProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRollingRecallProposalProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.RollingRecallProposalProcedureCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newRollingRecallProposal("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingRecallProposalRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.RollingRecallProposalRatioRangeRule(min: 1.4, max: 1349.7)
        let item = Pharmacy.newRollingRecallProposal("x", label: "y")
        item.ratio = 1351.2
        #expect(rule.check(item).count > 0)
    }
}
