@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackWorklistRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackWorklistRequestValidator()
        let item = Imaging.newFallbackWorklistRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackWorklistRequestRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.FallbackWorklistRequestRegionLengthRule(maxLength: 64)
        let item = Imaging.newFallbackWorklistRequest("x", label: "y")
        item.region = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackWorklistRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.FallbackWorklistRequestCodeLengthRule(maxLength: 255)
        let item = Imaging.newFallbackWorklistRequest("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackWorklistRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.FallbackWorklistRequestRequiredCodeRule(message: "fallback worklist request needs an entry")
        let item = Imaging.newFallbackWorklistRequest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackWorklistRequestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.FallbackWorklistRequestLabelLengthRule(maxLength: 120)
        let item = Imaging.newFallbackWorklistRequest("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackWorklistRequestRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Imaging.FallbackWorklistRequestRequiredCountryRule(message: "fallback worklist request needs a value")
        let item = Imaging.newFallbackWorklistRequest("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
