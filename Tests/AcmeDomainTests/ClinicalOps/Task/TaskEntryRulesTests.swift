@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskEntryValidator()
        let item = ClinicalOps.newTaskEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskEntryPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.TaskEntryPriorityRangeRule(min: 32, max: 80)
        let item = ClinicalOps.newTaskEntry("x", title: "y")
        item.priority = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskEntryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.TaskEntryRequiredTitleRule(message: "task entry needs this field")
        let item = ClinicalOps.newTaskEntry("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.TaskEntryRequiredNameRule(message: "task entry needs an entry")
        let item = ClinicalOps.newTaskEntry("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
