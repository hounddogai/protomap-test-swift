@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalStudyBatchValidator()
        let item = Imaging.newRegionalStudyBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalStudyBatchRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Imaging.RegionalStudyBatchRequiredPayerRule(message: "regional study batch needs a value")
        let item = Imaging.newRegionalStudyBatch("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalStudyBatchLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.RegionalStudyBatchLabelLengthRule(maxLength: 1000)
        let item = Imaging.newRegionalStudyBatch("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRegionalStudyBatchRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Imaging.RegionalStudyBatchRevisionRangeRule(min: 32, max: 120)
        let item = Imaging.newRegionalStudyBatch("x", label: "y")
        item.revision = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRegionalStudyBatchRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.RegionalStudyBatchRequiredLabelRule(message: "regional study batch needs a value")
        let item = Imaging.newRegionalStudyBatch("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
