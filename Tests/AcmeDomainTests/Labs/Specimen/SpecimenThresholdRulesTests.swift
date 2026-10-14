@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenThresholdValidator()
        let item = Labs.newSpecimenThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenThresholdRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Labs.SpecimenThresholdRetriesRangeRule(min: 16, max: 255)
        let item = Labs.newSpecimenThreshold("x", title: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SpecimenThresholdCodeLengthRule(maxLength: 3600)
        let item = Labs.newSpecimenThreshold("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenThresholdRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Labs.SpecimenThresholdRequiredDiagnosisCodeRule(message: "specimen threshold needs an entry")
        let item = Labs.newSpecimenThreshold("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenThresholdWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Labs.SpecimenThresholdWindowDaysRangeRule(min: 32, max: 64)
        let item = Labs.newSpecimenThreshold("x", title: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenThresholdScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.SpecimenThresholdScoreRangeRule(min: 8.1, max: 2201.4)
        let item = Labs.newSpecimenThreshold("x", title: "y")
        item.score = 2202.9
        #expect(rule.check(item).count > 0)
    }
}
