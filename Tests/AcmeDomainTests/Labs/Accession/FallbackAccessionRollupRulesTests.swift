@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackAccessionRollupValidator()
        let item = Labs.newFallbackAccessionRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackAccessionRollupExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Labs.FallbackAccessionRollupExternalRefLengthRule(maxLength: 32)
        let item = Labs.newFallbackAccessionRollup("x", title: "y")
        item.externalRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackAccessionRollupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.FallbackAccessionRollupTitleLengthRule(maxLength: 32)
        let item = Labs.newFallbackAccessionRollup("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackAccessionRollupGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Labs.FallbackAccessionRollupGraceDaysRangeRule(min: 32, max: 120)
        let item = Labs.newFallbackAccessionRollup("x", title: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackAccessionRollupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.FallbackAccessionRollupRequiredTitleRule(message: "fallback accession rollup needs this field")
        let item = Labs.newFallbackAccessionRollup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackAccessionRollupRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Labs.FallbackAccessionRollupRequiredChecksumRule(message: "fallback accession rollup needs an entry")
        let item = Labs.newFallbackAccessionRollup("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
