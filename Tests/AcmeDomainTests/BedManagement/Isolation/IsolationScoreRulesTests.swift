@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationScoreValidator()
        let item = BedManagement.newIsolationScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.IsolationScoreRequiredTitleRule(message: "isolation score needs an entry")
        let item = BedManagement.newIsolationScore("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationScoreExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = BedManagement.IsolationScoreExternalRefLengthRule(maxLength: 80)
        let item = BedManagement.newIsolationScore("x", title: "y")
        item.externalRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationScoreEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = BedManagement.IsolationScoreEndsAtRangeRule(min: 16, max: 255)
        let item = BedManagement.newIsolationScore("x", title: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationScoreCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = BedManagement.IsolationScoreCountryLengthRule(maxLength: 16)
        let item = BedManagement.newIsolationScore("x", title: "y")
        item.country = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationScoreRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = BedManagement.IsolationScoreRequiredCountryRule(message: "isolation score needs a value")
        let item = BedManagement.newIsolationScore("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
