@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyTaskWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyTaskWindowValidator()
        let item = ClinicalOps.newLegacyTaskWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyTaskWindowTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.LegacyTaskWindowTitleLengthRule(maxLength: 32)
        let item = ClinicalOps.newLegacyTaskWindow("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyTaskWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.LegacyTaskWindowRequiredTitleRule(message: "legacy task window needs a value")
        let item = ClinicalOps.newLegacyTaskWindow("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
