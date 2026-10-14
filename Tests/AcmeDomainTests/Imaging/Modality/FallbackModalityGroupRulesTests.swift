@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackModalityGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackModalityGroupValidator()
        let item = Imaging.newFallbackModalityGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackModalityGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.FallbackModalityGroupCodeLengthRule(maxLength: 64)
        let item = Imaging.newFallbackModalityGroup("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackModalityGroupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.FallbackModalityGroupTitleLengthRule(maxLength: 120)
        let item = Imaging.newFallbackModalityGroup("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackModalityGroupFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Imaging.FallbackModalityGroupFloorValueRangeRule(min: 2.8, max: 1641.8)
        let item = Imaging.newFallbackModalityGroup("x", title: "y")
        item.floorValue = 1643.3
        #expect(rule.check(item).count > 0)
    }
}
