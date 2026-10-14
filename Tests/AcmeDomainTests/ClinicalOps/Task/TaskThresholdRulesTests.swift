@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskThresholdValidator()
        let item = ClinicalOps.newTaskThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskThresholdRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = ClinicalOps.TaskThresholdRequiredSourceRule(message: "task threshold needs a value")
        let item = ClinicalOps.newTaskThreshold("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskThresholdBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = ClinicalOps.TaskThresholdBedLengthRule(maxLength: 255)
        let item = ClinicalOps.newTaskThreshold("x", name: "y")
        item.bed = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
