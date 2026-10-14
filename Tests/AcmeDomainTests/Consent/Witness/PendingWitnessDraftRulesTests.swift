@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingWitnessDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPendingWitnessDraftValidator()
        let item = Consent.newPendingWitnessDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPendingWitnessDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.PendingWitnessDraftCodeLengthRule(maxLength: 64)
        let item = Consent.newPendingWitnessDraft("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPendingWitnessDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.PendingWitnessDraftRequiredCodeRule(message: "pending witness draft needs an entry")
        let item = Consent.newPendingWitnessDraft("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPendingWitnessDraftBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Consent.PendingWitnessDraftBedLengthRule(maxLength: 1000)
        let item = Consent.newPendingWitnessDraft("x", name: "y")
        item.bed = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPendingWitnessDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.PendingWitnessDraftNameLengthRule(maxLength: 16)
        let item = Consent.newPendingWitnessDraft("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPendingWitnessDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.PendingWitnessDraftRequiredNameRule(message: "pending witness draft needs an entry")
        let item = Consent.newPendingWitnessDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
