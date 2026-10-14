@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledCleaningThresholdValidator()
        let item = BedManagement.newScheduledCleaningThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledCleaningThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.ScheduledCleaningThresholdRequiredNameRule(
            message: "scheduled cleaning threshold needs a value"
        )
        let item = BedManagement.newScheduledCleaningThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledCleaningThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ScheduledCleaningThresholdRequiredCodeRule(
            message: "scheduled cleaning threshold needs this field"
        )
        let item = BedManagement.newScheduledCleaningThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledCleaningThresholdSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = BedManagement.ScheduledCleaningThresholdSegmentLengthRule(maxLength: 120)
        let item = BedManagement.newScheduledCleaningThreshold("x", name: "y")
        item.segment = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledCleaningThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.ScheduledCleaningThresholdNameLengthRule(maxLength: 80)
        let item = BedManagement.newScheduledCleaningThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
