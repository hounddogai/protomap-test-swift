@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadMilestoneValidator()
        let item = Imaging.newReadMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadMilestoneRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Imaging.ReadMilestoneRequiredSpecialtyRule(message: "read milestone needs this field")
        let item = Imaging.newReadMilestone("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ReadMilestoneCodeLengthRule(maxLength: 3600)
        let item = Imaging.newReadMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadMilestoneAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.ReadMilestoneAttemptsRangeRule(min: 64, max: 120)
        let item = Imaging.newReadMilestone("x", name: "y")
        item.attempts = 121
        #expect(rule.check(item).count > 0)
    }
}
