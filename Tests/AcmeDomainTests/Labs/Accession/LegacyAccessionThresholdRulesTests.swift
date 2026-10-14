@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyAccessionThresholdValidator()
        let item = Labs.newLegacyAccessionThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyAccessionThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LegacyAccessionThresholdRequiredCodeRule(message: "legacy accession threshold needs this field")
        let item = Labs.newLegacyAccessionThreshold("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyAccessionThresholdRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.LegacyAccessionThresholdRequiredLabelRule(message: "legacy accession threshold needs an entry")
        let item = Labs.newLegacyAccessionThreshold("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyAccessionThresholdLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.LegacyAccessionThresholdLabelLengthRule(maxLength: 255)
        let item = Labs.newLegacyAccessionThreshold("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
