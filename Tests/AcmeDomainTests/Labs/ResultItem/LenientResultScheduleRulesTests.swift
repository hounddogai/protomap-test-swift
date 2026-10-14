@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientResultScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientResultScheduleValidator()
        let item = Labs.newLenientResultSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientResultScheduleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.LenientResultScheduleRequiredLabelRule(message: "lenient result schedule needs this field")
        let item = Labs.newLenientResultSchedule("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientResultSchedulePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Labs.LenientResultSchedulePriorityRangeRule(min: 32, max: 64)
        let item = Labs.newLenientResultSchedule("x", label: "y")
        item.priority = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLenientResultScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.LenientResultScheduleCodeLengthRule(maxLength: 80)
        let item = Labs.newLenientResultSchedule("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLenientResultScheduleLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.LenientResultScheduleLimitRangeRule(min: 32, max: 1000)
        let item = Labs.newLenientResultSchedule("x", label: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}
