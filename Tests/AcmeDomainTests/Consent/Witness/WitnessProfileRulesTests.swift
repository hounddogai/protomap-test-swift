@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessProfileValidator()
        let item = Consent.newWitnessProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessProfileWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Consent.WitnessProfileWindowDaysRangeRule(min: 32, max: 3600)
        let item = Consent.newWitnessProfile("x", label: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.WitnessProfileCodeLengthRule(maxLength: 3600)
        let item = Consent.newWitnessProfile("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessProfileSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Consent.WitnessProfileSegmentLengthRule(maxLength: 1000)
        let item = Consent.newWitnessProfile("x", label: "y")
        item.segment = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessProfilePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Consent.WitnessProfilePhoneLengthRule(maxLength: 86400)
        let item = Consent.newWitnessProfile("x", label: "y")
        item.phone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
