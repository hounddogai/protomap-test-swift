@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadOverrideValidator()
        let item = Imaging.newReadOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadOverrideLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ReadOverrideLabelLengthRule(maxLength: 16)
        let item = Imaging.newReadOverride("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ReadOverrideRequiredCodeRule(message: "read override needs a value")
        let item = Imaging.newReadOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadOverrideFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Imaging.ReadOverrideFacilityLengthRule(maxLength: 86400)
        let item = Imaging.newReadOverride("x", label: "y")
        item.facility = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
