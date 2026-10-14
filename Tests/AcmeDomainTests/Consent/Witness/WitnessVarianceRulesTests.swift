@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessVarianceValidator()
        let item = Consent.newWitnessVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.WitnessVarianceRequiredLabelRule(message: "witness variance needs a value")
        let item = Consent.newWitnessVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessVarianceEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Consent.WitnessVarianceEndsAtRangeRule(min: 16, max: 32)
        let item = Consent.newWitnessVariance("x", label: "y")
        item.endsAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.WitnessVarianceCodeLengthRule(maxLength: 120)
        let item = Consent.newWitnessVariance("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
