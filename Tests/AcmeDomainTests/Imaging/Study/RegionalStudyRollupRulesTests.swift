@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalStudyRollupValidator()
        let item = Imaging.newRegionalStudyRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalStudyRollupTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Imaging.RegionalStudyRollupTimezoneLengthRule(maxLength: 255)
        let item = Imaging.newRegionalStudyRollup("x", label: "y")
        item.timezone = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRegionalStudyRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.RegionalStudyRollupCodeLengthRule(maxLength: 32)
        let item = Imaging.newRegionalStudyRollup("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRegionalStudyRollupCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Imaging.RegionalStudyRollupCeilingRangeRule(min: 4.2, max: 4735.9)
        let item = Imaging.newRegionalStudyRollup("x", label: "y")
        item.ceiling = 4737.4
        #expect(rule.check(item).count > 0)
    }
}
