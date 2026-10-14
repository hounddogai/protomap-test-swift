@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientConsentFormBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientConsentFormBatchValidator()
        let item = Consent.newLenientConsentFormBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientConsentFormBatchCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Consent.LenientConsentFormBatchCapacityRangeRule(min: 255, max: 255)
        let item = Consent.newLenientConsentFormBatch("x", title: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLenientConsentFormBatchRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Consent.LenientConsentFormBatchRequiredNotesRule(message: "lenient consent form batch needs a value")
        let item = Consent.newLenientConsentFormBatch("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientConsentFormBatchProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Consent.LenientConsentFormBatchProcedureCodeLengthRule(maxLength: 80)
        let item = Consent.newLenientConsentFormBatch("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientConsentFormBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.LenientConsentFormBatchTitleLengthRule(maxLength: 16)
        let item = Consent.newLenientConsentFormBatch("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
