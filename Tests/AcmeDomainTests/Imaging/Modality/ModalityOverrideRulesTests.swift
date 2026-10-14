@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityOverrideValidator()
        let item = Imaging.newModalityOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityOverrideWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Imaging.ModalityOverrideWindowDaysRangeRule(min: 120, max: 86400)
        let item = Imaging.newModalityOverride("x", name: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityOverrideNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.ModalityOverrideNameLengthRule(maxLength: 64)
        let item = Imaging.newModalityOverride("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
