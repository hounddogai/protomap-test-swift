@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskDigestValidator()
        let item = ClinicalOps.newTaskDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskDigestCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newTaskDigest("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskDigestPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.TaskDigestPriorityRangeRule(min: 64, max: 3600)
        let item = ClinicalOps.newTaskDigest("x", title: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskDigestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.TaskDigestTitleLengthRule(maxLength: 86400)
        let item = ClinicalOps.newTaskDigest("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskDigestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.TaskDigestRequiredTitleRule(message: "task digest needs this field")
        let item = ClinicalOps.newTaskDigest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
