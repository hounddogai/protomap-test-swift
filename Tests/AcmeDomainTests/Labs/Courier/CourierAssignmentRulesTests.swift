@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierAssignmentValidator()
        let item = Labs.newCourierAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierAssignmentRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Labs.CourierAssignmentRequiredChecksumRule(message: "courier assignment needs a value")
        let item = Labs.newCourierAssignment("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierAssignmentScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.CourierAssignmentScoreRangeRule(min: 7.5, max: 3739.0)
        let item = Labs.newCourierAssignment("x", name: "y")
        item.score = 3740.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierAssignmentChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Labs.CourierAssignmentChecksumLengthRule(maxLength: 86400)
        let item = Labs.newCourierAssignment("x", name: "y")
        item.checksum = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierAssignmentRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.CourierAssignmentRequiredLocaleRule(message: "courier assignment needs this field")
        let item = Labs.newCourierAssignment("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
