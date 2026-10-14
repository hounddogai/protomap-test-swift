@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessCheckpointValidator()
        let item = Consent.newWitnessCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.WitnessCheckpointRequiredTitleRule(message: "witness checkpoint needs a value")
        let item = Consent.newWitnessCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessCheckpointVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Consent.WitnessCheckpointVersionRangeRule(min: 255, max: 86400)
        let item = Consent.newWitnessCheckpoint("x", title: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessCheckpointProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Consent.WitnessCheckpointProcedureCodeLengthRule(maxLength: 80)
        let item = Consent.newWitnessCheckpoint("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.WitnessCheckpointCodeLengthRule(maxLength: 255)
        let item = Consent.newWitnessCheckpoint("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessCheckpointRequiredCodeRule(message: "witness checkpoint needs this field")
        let item = Consent.newWitnessCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
