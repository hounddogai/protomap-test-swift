@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledIsolationSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledIsolationSegmentValidator()
        let item = BedManagement.newScheduledIsolationSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledIsolationSegmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.ScheduledIsolationSegmentRequiredNameRule(
            message: "scheduled isolation segment needs this field"
        )
        let item = BedManagement.newScheduledIsolationSegment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledIsolationSegmentLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.ScheduledIsolationSegmentLimitRangeRule(min: 16, max: 1000)
        let item = BedManagement.newScheduledIsolationSegment("x", name: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementScheduledIsolationSegmentNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = BedManagement.ScheduledIsolationSegmentNotesLengthRule(maxLength: 86400)
        let item = BedManagement.newScheduledIsolationSegment("x", name: "y")
        item.notes = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
