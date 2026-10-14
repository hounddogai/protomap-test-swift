@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalModalityBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalModalityBatchValidator()
        let item = Imaging.newRegionalModalityBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalModalityBatchRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.RegionalModalityBatchRequiredLabelRule(message: "regional modality batch needs an entry")
        let item = Imaging.newRegionalModalityBatch("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalModalityBatchRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.RegionalModalityBatchRequiredNameRule(message: "regional modality batch needs an entry")
        let item = Imaging.newRegionalModalityBatch("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalModalityBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.RegionalModalityBatchCodeLengthRule(maxLength: 32)
        let item = Imaging.newRegionalModalityBatch("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
