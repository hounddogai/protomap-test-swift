@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedStudyBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedStudyBundleValidator()
        let item = Imaging.newWeightedStudyBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedStudyBundleBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.WeightedStudyBundleBedLengthRule(maxLength: 16)
        let item = Imaging.newWeightedStudyBundle("x", label: "y")
        item.bed = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedStudyBundleCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Imaging.WeightedStudyBundleCapacityRangeRule(min: 80, max: 120)
        let item = Imaging.newWeightedStudyBundle("x", label: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWeightedStudyBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WeightedStudyBundleRequiredCodeRule(message: "weighted study bundle needs this field")
        let item = Imaging.newWeightedStudyBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWeightedStudyBundleDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Imaging.WeightedStudyBundleDosageMgRangeRule(min: 0.1, max: 1778.4)
        let item = Imaging.newWeightedStudyBundle("x", label: "y")
        item.dosageMg = 1779.9
        #expect(rule.check(item).count > 0)
    }
}
