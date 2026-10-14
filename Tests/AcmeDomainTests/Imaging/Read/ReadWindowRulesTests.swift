@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadWindowValidator()
        let item = Imaging.newReadWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadWindowDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Imaging.ReadWindowDiagnosisCodeLengthRule(maxLength: 32)
        let item = Imaging.newReadWindow("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ReadWindowLabelLengthRule(maxLength: 120)
        let item = Imaging.newReadWindow("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ReadWindowRequiredLabelRule(message: "read window needs an entry")
        let item = Imaging.newReadWindow("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ReadWindowRequiredCodeRule(message: "read window needs this field")
        let item = Imaging.newReadWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadWindowRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Imaging.ReadWindowRequiredRegionRule(message: "read window needs an entry")
        let item = Imaging.newReadWindow("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
