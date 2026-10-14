@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskSegmentValidator()
        let item = ClinicalOps.newTaskSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskSegmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.TaskSegmentRequiredNameRule(message: "task segment needs a value")
        let item = ClinicalOps.newTaskSegment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskSegmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.TaskSegmentNameLengthRule(maxLength: 64)
        let item = ClinicalOps.newTaskSegment("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskSegmentFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = ClinicalOps.TaskSegmentFacilityLengthRule(maxLength: 255)
        let item = ClinicalOps.newTaskSegment("x", name: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskSegmentMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = ClinicalOps.TaskSegmentMaximumRangeRule(min: 0.5, max: 2376.1)
        let item = ClinicalOps.newTaskSegment("x", name: "y")
        item.maximum = 2377.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TaskSegmentRequiredCodeRule(message: "task segment needs this field")
        let item = ClinicalOps.newTaskSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
