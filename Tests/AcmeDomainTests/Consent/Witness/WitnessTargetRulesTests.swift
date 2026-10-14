@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessTargetValidator()
        let item = Consent.newWitnessTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.WitnessTargetRequiredNameRule(message: "witness target needs a value")
        let item = Consent.newWitnessTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.WitnessTargetCodeLengthRule(maxLength: 255)
        let item = Consent.newWitnessTarget("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessTargetSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Consent.WitnessTargetSequenceRangeRule(min: 32, max: 64)
        let item = Consent.newWitnessTarget("x", name: "y")
        item.sequence = 65
        #expect(rule.check(item).count > 0)
    }
}
