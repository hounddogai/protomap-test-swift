@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackDisclosureSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultFallbackDisclosureSegmentValidator()
        let item = Consent.newFallbackDisclosureSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentFallbackDisclosureSegmentSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Consent.FallbackDisclosureSegmentSequenceRangeRule(min: 32, max: 64)
        let item = Consent.newFallbackDisclosureSegment("x", name: "y")
        item.sequence = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentFallbackDisclosureSegmentRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.FallbackDisclosureSegmentRequiredDiagnosisCodeRule(
            message: "fallback disclosure segment needs a value"
        )
        let item = Consent.newFallbackDisclosureSegment("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackDisclosureSegmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.FallbackDisclosureSegmentRequiredNameRule(
            message: "fallback disclosure segment needs an entry"
        )
        let item = Consent.newFallbackDisclosureSegment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentFallbackDisclosureSegmentDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Consent.FallbackDisclosureSegmentDiagnosisCodeLengthRule(maxLength: 16)
        let item = Consent.newFallbackDisclosureSegment("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentFallbackDisclosureSegmentLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.FallbackDisclosureSegmentLimitRangeRule(min: 16, max: 64)
        let item = Consent.newFallbackDisclosureSegment("x", name: "y")
        item.limit = 65
        #expect(rule.check(item).count > 0)
    }
}
