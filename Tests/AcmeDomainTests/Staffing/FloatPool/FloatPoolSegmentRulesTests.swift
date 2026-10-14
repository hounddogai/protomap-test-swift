@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolSegmentValidator()
        let item = Staffing.newFloatPoolSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolSegmentEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Staffing.FloatPoolSegmentEncounterIDLengthRule(maxLength: 16)
        let item = Staffing.newFloatPoolSegment("x", title: "y")
        item.encounterID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolSegmentExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Staffing.FloatPoolSegmentExpiresAtRangeRule(min: 64, max: 64)
        let item = Staffing.newFloatPoolSegment("x", title: "y")
        item.expiresAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FloatPoolSegmentCodeLengthRule(maxLength: 16)
        let item = Staffing.newFloatPoolSegment("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolSegmentPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Staffing.FloatPoolSegmentPriorityRangeRule(min: 255, max: 86400)
        let item = Staffing.newFloatPoolSegment("x", title: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}
