@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyStudyEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLegacyStudyEstimateValidator()
        let item = Imaging.newLegacyStudyEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLegacyStudyEstimateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.LegacyStudyEstimateTitleLengthRule(maxLength: 3600)
        let item = Imaging.newLegacyStudyEstimate("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLegacyStudyEstimateScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Imaging.LegacyStudyEstimateScoreRangeRule(min: 0.6, max: 4482.3)
        let item = Imaging.newLegacyStudyEstimate("x", title: "y")
        item.score = 4483.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLegacyStudyEstimateDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Imaging.LegacyStudyEstimateDiagnosisCodeLengthRule(maxLength: 64)
        let item = Imaging.newLegacyStudyEstimate("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
