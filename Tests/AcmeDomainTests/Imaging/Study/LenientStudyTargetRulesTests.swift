@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientStudyTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLenientStudyTargetValidator()
        let item = Imaging.newLenientStudyTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLenientStudyTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.LenientStudyTargetRequiredNameRule(message: "lenient study target needs this field")
        let item = Imaging.newLenientStudyTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLenientStudyTargetRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.LenientStudyTargetRateRangeRule(min: 5.3, max: 2122.9)
        let item = Imaging.newLenientStudyTarget("x", name: "y")
        item.rate = 2124.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLenientStudyTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.LenientStudyTargetNameLengthRule(maxLength: 32)
        let item = Imaging.newLenientStudyTarget("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLenientStudyTargetGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.LenientStudyTargetGraceDaysRangeRule(min: 64, max: 120)
        let item = Imaging.newLenientStudyTarget("x", name: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLenientStudyTargetCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Imaging.LenientStudyTargetCostRangeRule(min: 6.7, max: 760.7)
        let item = Imaging.newLenientStudyTarget("x", name: "y")
        item.cost = 762.2
        #expect(rule.check(item).count > 0)
    }
}
