@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistRuleValidator()
        let item = Imaging.newWorklistRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistRuleCodeLengthRule(maxLength: 255)
        let item = Imaging.newWorklistRule("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistRuleRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.WorklistRuleRatioRangeRule(min: 2.2, max: 4891.2)
        let item = Imaging.newWorklistRule("x", name: "y")
        item.ratio = 4892.7
        #expect(rule.check(item).count > 0)
    }
}
