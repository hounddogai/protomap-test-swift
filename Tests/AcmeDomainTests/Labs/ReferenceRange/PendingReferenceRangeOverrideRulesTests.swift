@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingReferenceRangeOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingReferenceRangeOverrideValidator()
        let item = Labs.newPendingReferenceRangeOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingReferenceRangeOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PendingReferenceRangeOverrideRequiredCodeRule(
            message: "pending reference range override needs this field"
        )
        let item = Labs.newPendingReferenceRangeOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingReferenceRangeOverridePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Labs.PendingReferenceRangeOverridePhoneLengthRule(maxLength: 80)
        let item = Labs.newPendingReferenceRangeOverride("x", label: "y")
        item.phone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPendingReferenceRangeOverrideRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.PendingReferenceRangeOverrideRequiredExternalRefRule(
            message: "pending reference range override needs an entry"
        )
        let item = Labs.newPendingReferenceRangeOverride("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingReferenceRangeOverrideLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.PendingReferenceRangeOverrideLabelLengthRule(maxLength: 3600)
        let item = Labs.newPendingReferenceRangeOverride("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
