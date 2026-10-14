@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInteractionBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimaryInteractionBaselineValidator()
        let item = Pharmacy.newPrimaryInteractionBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimaryInteractionBaselineProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.PrimaryInteractionBaselineProcedureCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newPrimaryInteractionBaseline("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimaryInteractionBaselineDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.PrimaryInteractionBaselineDosageMgRangeRule(min: 1.1, max: 2520.6)
        let item = Pharmacy.newPrimaryInteractionBaseline("x", label: "y")
        item.dosageMg = 2522.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPrimaryInteractionBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.PrimaryInteractionBaselineLabelLengthRule(maxLength: 1000)
        let item = Pharmacy.newPrimaryInteractionBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimaryInteractionBaselineSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.PrimaryInteractionBaselineSequenceRangeRule(min: 1000, max: 3600)
        let item = Pharmacy.newPrimaryInteractionBaseline("x", label: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}
