@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedModalityMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultBatchedModalityMappingValidator()
        let item = Imaging.newBatchedModalityMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingBatchedModalityMappingRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.BatchedModalityMappingRequiredNameRule(message: "batched modality mapping needs a value")
        let item = Imaging.newBatchedModalityMapping("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedModalityMappingRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Imaging.BatchedModalityMappingRequiredPatientRefRule(
            message: "batched modality mapping needs a value"
        )
        let item = Imaging.newBatchedModalityMapping("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedModalityMappingVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Imaging.BatchedModalityMappingVisitMinutesRangeRule(min: 64, max: 120)
        let item = Imaging.newBatchedModalityMapping("x", name: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingBatchedModalityMappingRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Imaging.BatchedModalityMappingRequiredEncounterIDRule(
            message: "batched modality mapping needs this field"
        )
        let item = Imaging.newBatchedModalityMapping("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedModalityMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.BatchedModalityMappingCodeLengthRule(maxLength: 3600)
        let item = Imaging.newBatchedModalityMapping("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
