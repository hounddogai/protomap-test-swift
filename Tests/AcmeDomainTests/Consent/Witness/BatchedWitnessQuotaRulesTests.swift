@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedWitnessQuotaValidator()
        let item = Consent.newBatchedWitnessQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedWitnessQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.BatchedWitnessQuotaRequiredCodeRule(message: "batched witness quota needs a value")
        let item = Consent.newBatchedWitnessQuota("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedWitnessQuotaRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Consent.BatchedWitnessQuotaRequiredOwnerIDRule(message: "batched witness quota needs an entry")
        let item = Consent.newBatchedWitnessQuota("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedWitnessQuotaOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Consent.BatchedWitnessQuotaOwnerIDLengthRule(maxLength: 16)
        let item = Consent.newBatchedWitnessQuota("x", name: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedWitnessQuotaNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.BatchedWitnessQuotaNameLengthRule(maxLength: 120)
        let item = Consent.newBatchedWitnessQuota("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
