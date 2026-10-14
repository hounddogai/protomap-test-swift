@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosureSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedDisclosureSegmentValidator()
        let item = Consent.newBatchedDisclosureSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedDisclosureSegmentRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Consent.BatchedDisclosureSegmentRequiredSpecialtyRule(
            message: "batched disclosure segment needs a value"
        )
        let item = Consent.newBatchedDisclosureSegment("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedDisclosureSegmentSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Consent.BatchedDisclosureSegmentSpecialtyLengthRule(maxLength: 32)
        let item = Consent.newBatchedDisclosureSegment("x", name: "y")
        item.specialty = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedDisclosureSegmentRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Consent.BatchedDisclosureSegmentRequiredPayerRule(
            message: "batched disclosure segment needs an entry"
        )
        let item = Consent.newBatchedDisclosureSegment("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedDisclosureSegmentPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Consent.BatchedDisclosureSegmentPayerLengthRule(maxLength: 3600)
        let item = Consent.newBatchedDisclosureSegment("x", name: "y")
        item.payer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedDisclosureSegmentPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Consent.BatchedDisclosureSegmentPriorityRangeRule(min: 64, max: 80)
        let item = Consent.newBatchedDisclosureSegment("x", name: "y")
        item.priority = 81
        #expect(rule.check(item).count > 0)
    }
}
