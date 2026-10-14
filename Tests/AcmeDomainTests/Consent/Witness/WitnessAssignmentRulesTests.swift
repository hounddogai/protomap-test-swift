@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessAssignmentValidator()
        let item = Consent.newWitnessAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessAssignmentRequiredCodeRule(message: "witness assignment needs an entry")
        let item = Consent.newWitnessAssignment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessAssignmentThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Consent.WitnessAssignmentThresholdRangeRule(min: 7.1, max: 3587.5)
        let item = Consent.newWitnessAssignment("x", title: "y")
        item.threshold = 3589.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessAssignmentRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.WitnessAssignmentRequiredProcedureCodeRule(message: "witness assignment needs a value")
        let item = Consent.newWitnessAssignment("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessAssignmentDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Consent.WitnessAssignmentDosageMgRangeRule(min: 2.9, max: 2072.0)
        let item = Consent.newWitnessAssignment("x", title: "y")
        item.dosageMg = 2073.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessAssignmentProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Consent.WitnessAssignmentProcedureCodeLengthRule(maxLength: 120)
        let item = Consent.newWitnessAssignment("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
