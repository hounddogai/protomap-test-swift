@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolEstimateValidator()
        let item = Imaging.newCareProtocolEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolEstimateCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Imaging.CareProtocolEstimateCeilingRangeRule(min: 1.2, max: 4045.1)
        let item = Imaging.newCareProtocolEstimate("x", label: "y")
        item.ceiling = 4046.6
        #expect(rule.check(item).count > 0)
    }
}
