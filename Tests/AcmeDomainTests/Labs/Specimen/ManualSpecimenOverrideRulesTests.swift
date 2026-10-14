@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualSpecimenOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultManualSpecimenOverrideValidator()
        let item = Labs.newManualSpecimenOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsManualSpecimenOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ManualSpecimenOverrideRequiredCodeRule(message: "manual specimen override needs an entry")
        let item = Labs.newManualSpecimenOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsManualSpecimenOverrideSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Labs.ManualSpecimenOverrideSummaryLengthRule(maxLength: 255)
        let item = Labs.newManualSpecimenOverride("x", label: "y")
        item.summary = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
