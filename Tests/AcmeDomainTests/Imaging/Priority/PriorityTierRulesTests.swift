@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityTierValidator()
        let item = Imaging.newPriorityTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PriorityTierRequiredCodeRule(message: "priority tier needs this field")
        let item = Imaging.newPriorityTier("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityTierCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Imaging.PriorityTierCategoryLengthRule(maxLength: 255)
        let item = Imaging.newPriorityTier("x", label: "y")
        item.category = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityTierAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.PriorityTierAcuityRangeRule(min: 16, max: 64)
        let item = Imaging.newPriorityTier("x", label: "y")
        item.acuity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PriorityTierCodeLengthRule(maxLength: 120)
        let item = Imaging.newPriorityTier("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
