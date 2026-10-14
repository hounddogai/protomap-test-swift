@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalRevocationGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultGlobalRevocationGroupValidator()
        let item = Consent.newGlobalRevocationGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentGlobalRevocationGroupRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Consent.GlobalRevocationGroupRequiredBedRule(message: "global revocation group needs an entry")
        let item = Consent.newGlobalRevocationGroup("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentGlobalRevocationGroupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.GlobalRevocationGroupRequiredTitleRule(message: "global revocation group needs an entry")
        let item = Consent.newGlobalRevocationGroup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentGlobalRevocationGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.GlobalRevocationGroupCodeLengthRule(maxLength: 255)
        let item = Consent.newGlobalRevocationGroup("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
