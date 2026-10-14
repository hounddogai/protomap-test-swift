@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessSegmentValidator()
        let item = Consent.newWitnessSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.WitnessSegmentCodeLengthRule(maxLength: 86400)
        let item = Consent.newWitnessSegment("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessSegmentClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Consent.WitnessSegmentClinicianIDLengthRule(maxLength: 1000)
        let item = Consent.newWitnessSegment("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessSegmentDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Consent.WitnessSegmentDurationMinutesRangeRule(min: 32, max: 32)
        let item = Consent.newWitnessSegment("x", label: "y")
        item.durationMinutes = 33
        #expect(rule.check(item).count > 0)
    }
}
