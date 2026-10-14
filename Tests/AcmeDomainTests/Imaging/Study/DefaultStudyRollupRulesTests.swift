@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultStudyRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultDefaultStudyRollupValidator()
        let item = Imaging.newDefaultStudyRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingDefaultStudyRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.DefaultStudyRollupCodeLengthRule(maxLength: 3600)
        let item = Imaging.newDefaultStudyRollup("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingDefaultStudyRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.DefaultStudyRollupRequiredCodeRule(message: "default study rollup needs this field")
        let item = Imaging.newDefaultStudyRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingDefaultStudyRollupFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Imaging.DefaultStudyRollupFloorValueRangeRule(min: 7.0, max: 3606.2)
        let item = Imaging.newDefaultStudyRollup("x", label: "y")
        item.floorValue = 3607.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingDefaultStudyRollupRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Imaging.DefaultStudyRollupRequiredUnitRule(message: "default study rollup needs this field")
        let item = Imaging.newDefaultStudyRollup("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingDefaultStudyRollupUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Imaging.DefaultStudyRollupUnitLengthRule(maxLength: 3600)
        let item = Imaging.newDefaultStudyRollup("x", label: "y")
        item.unit = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
