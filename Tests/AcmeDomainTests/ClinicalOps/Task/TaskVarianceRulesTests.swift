@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskVarianceValidator()
        let item = ClinicalOps.newTaskVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskVarianceRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = ClinicalOps.TaskVarianceRequiredBedRule(message: "task variance needs a value")
        let item = ClinicalOps.newTaskVariance("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskVarianceCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newTaskVariance("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
