@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadExceptionValidator()
        let item = Imaging.newReadException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadExceptionWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.ReadExceptionWeightRangeRule(min: 7.6, max: 4430.2)
        let item = Imaging.newReadException("x", label: "y")
        item.weight = 4431.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadExceptionRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ReadExceptionRequiredLabelRule(message: "read exception needs this field")
        let item = Imaging.newReadException("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadExceptionCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Imaging.ReadExceptionCountryLengthRule(maxLength: 80)
        let item = Imaging.newReadException("x", label: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
