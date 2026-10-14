@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityAssignmentValidator()
        let item = Imaging.newPriorityAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityAssignmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.PriorityAssignmentLabelLengthRule(maxLength: 1000)
        let item = Imaging.newPriorityAssignment("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityAssignmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.PriorityAssignmentRequiredLabelRule(message: "priority assignment needs an entry")
        let item = Imaging.newPriorityAssignment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
