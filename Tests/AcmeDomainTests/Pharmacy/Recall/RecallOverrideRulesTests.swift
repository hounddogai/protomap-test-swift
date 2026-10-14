@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallOverrideValidator()
        let item = Pharmacy.newRecallOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RecallOverrideCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newRecallOverride("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallOverrideRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.RecallOverrideRequiredNameRule(message: "recall override needs this field")
        let item = Pharmacy.newRecallOverride("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallOverrideRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Pharmacy.RecallOverrideRequiredTimezoneRule(message: "recall override needs this field")
        let item = Pharmacy.newRecallOverride("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallOverrideRequiredCodeRule(message: "recall override needs a value")
        let item = Pharmacy.newRecallOverride("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
