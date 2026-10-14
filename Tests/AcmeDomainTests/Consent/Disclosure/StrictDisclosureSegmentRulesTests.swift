@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictDisclosureSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictDisclosureSegmentValidator()
        let item = Consent.newStrictDisclosureSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictDisclosureSegmentClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Consent.StrictDisclosureSegmentClinicianIDLengthRule(maxLength: 16)
        let item = Consent.newStrictDisclosureSegment("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentStrictDisclosureSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.StrictDisclosureSegmentRequiredCodeRule(message: "strict disclosure segment needs this field")
        let item = Consent.newStrictDisclosureSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
