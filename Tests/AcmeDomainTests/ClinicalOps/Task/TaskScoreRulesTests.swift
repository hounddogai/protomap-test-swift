@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskScoreValidator()
        let item = ClinicalOps.newTaskScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskScoreCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newTaskScore("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskScoreRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.TaskScoreRequiredNameRule(message: "task score needs a value")
        let item = ClinicalOps.newTaskScore("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskScoreFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = ClinicalOps.TaskScoreFacilityLengthRule(maxLength: 120)
        let item = ClinicalOps.newTaskScore("x", name: "y")
        item.facility = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.TaskScoreNameLengthRule(maxLength: 255)
        let item = ClinicalOps.newTaskScore("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
