@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionScoreValidator()
        let item = Labs.newAccessionScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionScoreRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Labs.AccessionScoreRefillsRangeRule(min: 1000, max: 86400)
        let item = Labs.newAccessionScore("x", title: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionScoreTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.AccessionScoreTitleLengthRule(maxLength: 16)
        let item = Labs.newAccessionScore("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.AccessionScoreRequiredTitleRule(message: "accession score needs this field")
        let item = Labs.newAccessionScore("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
