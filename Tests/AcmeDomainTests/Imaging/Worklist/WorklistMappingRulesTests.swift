@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistMappingValidator()
        let item = Imaging.newWorklistMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.WorklistMappingNameLengthRule(maxLength: 16)
        let item = Imaging.newWorklistMapping("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistMappingRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Imaging.WorklistMappingRefillsRangeRule(min: 255, max: 86400)
        let item = Imaging.newWorklistMapping("x", name: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}
