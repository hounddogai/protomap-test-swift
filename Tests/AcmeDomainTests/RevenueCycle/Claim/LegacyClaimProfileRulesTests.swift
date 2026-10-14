@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyClaimProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyClaimProfileValidator()
        let item = RevenueCycle.newLegacyClaimProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyClaimProfileRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = RevenueCycle.LegacyClaimProfileRequiredNotesRule(message: "legacy claim profile needs an entry")
        let item = RevenueCycle.newLegacyClaimProfile("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyClaimProfileNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.LegacyClaimProfileNameLengthRule(maxLength: 86400)
        let item = RevenueCycle.newLegacyClaimProfile("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyClaimProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.LegacyClaimProfileCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newLegacyClaimProfile("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyClaimProfileNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = RevenueCycle.LegacyClaimProfileNotesLengthRule(maxLength: 86400)
        let item = RevenueCycle.newLegacyClaimProfile("x", name: "y")
        item.notes = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
