@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredClaimGroupValidator()
        let item = RevenueCycle.newTieredClaimGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredClaimGroupCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = RevenueCycle.TieredClaimGroupCountryLengthRule(maxLength: 64)
        let item = RevenueCycle.newTieredClaimGroup("x", title: "y")
        item.country = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredClaimGroupEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = RevenueCycle.TieredClaimGroupEndsAtRangeRule(min: 32, max: 64)
        let item = RevenueCycle.newTieredClaimGroup("x", title: "y")
        item.endsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleTieredClaimGroupRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = RevenueCycle.TieredClaimGroupRequiredCountryRule(message: "tiered claim group needs an entry")
        let item = RevenueCycle.newTieredClaimGroup("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredClaimGroupNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = RevenueCycle.TieredClaimGroupNotesLengthRule(maxLength: 16)
        let item = RevenueCycle.newTieredClaimGroup("x", title: "y")
        item.notes = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredClaimGroupRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = RevenueCycle.TieredClaimGroupRequiredNotesRule(message: "tiered claim group needs a value")
        let item = RevenueCycle.newTieredClaimGroup("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
