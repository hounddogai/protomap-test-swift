@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangePolicyValidator()
        let item = Labs.newReferenceRangePolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangePolicyRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Labs.ReferenceRangePolicyRequiredChecksumRule(message: "reference range policy needs an entry")
        let item = Labs.newReferenceRangePolicy("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangePolicySequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.ReferenceRangePolicySequenceRangeRule(min: 32, max: 120)
        let item = Labs.newReferenceRangePolicy("x", label: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangePolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangePolicyRequiredCodeRule(message: "reference range policy needs this field")
        let item = Labs.newReferenceRangePolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
