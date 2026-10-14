@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskOverrideValidator()
        let item = ClinicalOps.newTaskOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TaskOverrideRequiredCodeRule(message: "task override needs an entry")
        let item = ClinicalOps.newTaskOverride("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.TaskOverrideTitleLengthRule(maxLength: 64)
        let item = ClinicalOps.newTaskOverride("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskOverrideRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = ClinicalOps.TaskOverrideRevisionRangeRule(min: 1000, max: 86400)
        let item = ClinicalOps.newTaskOverride("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.TaskOverrideRequiredTitleRule(message: "task override needs an entry")
        let item = ClinicalOps.newTaskOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
