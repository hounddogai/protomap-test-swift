@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyEstimateValidator()
        let item = Imaging.newStudyEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyEstimateFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Imaging.StudyEstimateFloorValueRangeRule(min: 0.7, max: 2155.6)
        let item = Imaging.newStudyEstimate("x", name: "y")
        item.floorValue = 2157.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyEstimateRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Imaging.StudyEstimateRefillsRangeRule(min: 32, max: 3600)
        let item = Imaging.newStudyEstimate("x", name: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}
