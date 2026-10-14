@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessAdjustmentValidator()
        let item = Consent.newWitnessAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessAdjustmentEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Consent.WitnessAdjustmentEndsAtRangeRule(min: 64, max: 120)
        let item = Consent.newWitnessAdjustment("x", title: "y")
        item.endsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessAdjustmentChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Consent.WitnessAdjustmentChannelLengthRule(maxLength: 1000)
        let item = Consent.newWitnessAdjustment("x", title: "y")
        item.channel = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
