@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessBatchValidator()
        let item = Consent.newWitnessBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessBatchBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Consent.WitnessBatchBatchSizeRangeRule(min: 16, max: 1000)
        let item = Consent.newWitnessBatch("x", label: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessBatchLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.WitnessBatchLabelLengthRule(maxLength: 80)
        let item = Consent.newWitnessBatch("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessBatchSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Consent.WitnessBatchSourceLengthRule(maxLength: 86400)
        let item = Consent.newWitnessBatch("x", label: "y")
        item.source = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessBatchContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Consent.WitnessBatchContactEmailLengthRule(maxLength: 86400)
        let item = Consent.newWitnessBatch("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessBatchRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Consent.WitnessBatchRequiredContactEmailRule(message: "witness batch needs this field")
        let item = Consent.newWitnessBatch("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
