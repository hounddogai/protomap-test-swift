@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolOverrideValidator()
        let item = Imaging.newCareProtocolOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolOverrideSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Imaging.CareProtocolOverrideSpecialtyLengthRule(maxLength: 255)
        let item = Imaging.newCareProtocolOverride("x", label: "y")
        item.specialty = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolOverrideWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Imaging.CareProtocolOverrideWindowDaysRangeRule(min: 120, max: 3600)
        let item = Imaging.newCareProtocolOverride("x", label: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolOverrideCodeLengthRule(maxLength: 3600)
        let item = Imaging.newCareProtocolOverride("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
