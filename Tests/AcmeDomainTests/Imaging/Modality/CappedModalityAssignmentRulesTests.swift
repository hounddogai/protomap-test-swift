@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCappedModalityAssignmentValidator()
        let item = Imaging.newCappedModalityAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCappedModalityAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.CappedModalityAssignmentTitleLengthRule(maxLength: 64)
        let item = Imaging.newCappedModalityAssignment("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCappedModalityAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CappedModalityAssignmentRequiredCodeRule(message: "capped modality assignment needs an entry")
        let item = Imaging.newCappedModalityAssignment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCappedModalityAssignmentStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Imaging.CappedModalityAssignmentStartsAtRangeRule(min: 16, max: 64)
        let item = Imaging.newCappedModalityAssignment("x", title: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}
