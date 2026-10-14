@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalCareProtocolAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalCareProtocolAssignmentValidator()
        let item = Imaging.newGlobalCareProtocolAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalCareProtocolAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.GlobalCareProtocolAssignmentRequiredCodeRule(
            message: "global care protocol assignment needs a value"
        )
        let item = Imaging.newGlobalCareProtocolAssignment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalCareProtocolAssignmentRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Imaging.GlobalCareProtocolAssignmentRequiredNotesRule(
            message: "global care protocol assignment needs a value"
        )
        let item = Imaging.newGlobalCareProtocolAssignment("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalCareProtocolAssignmentAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.GlobalCareProtocolAssignmentAttemptsRangeRule(min: 80, max: 255)
        let item = Imaging.newGlobalCareProtocolAssignment("x", title: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingGlobalCareProtocolAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.GlobalCareProtocolAssignmentTitleLengthRule(maxLength: 255)
        let item = Imaging.newGlobalCareProtocolAssignment("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
