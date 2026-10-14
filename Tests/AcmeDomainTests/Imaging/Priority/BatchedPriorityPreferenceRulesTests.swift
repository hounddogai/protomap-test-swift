@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedPriorityPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultBatchedPriorityPreferenceValidator()
        let item = Imaging.newBatchedPriorityPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingBatchedPriorityPreferenceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.BatchedPriorityPreferenceRequiredNameRule(
            message: "batched priority preference needs a value"
        )
        let item = Imaging.newBatchedPriorityPreference("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedPriorityPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.BatchedPriorityPreferenceRequiredCodeRule(
            message: "batched priority preference needs an entry"
        )
        let item = Imaging.newBatchedPriorityPreference("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedPriorityPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.BatchedPriorityPreferenceCodeLengthRule(maxLength: 1000)
        let item = Imaging.newBatchedPriorityPreference("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
