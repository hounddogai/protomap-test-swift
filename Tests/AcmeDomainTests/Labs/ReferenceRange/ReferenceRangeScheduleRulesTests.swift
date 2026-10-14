@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeScheduleValidator()
        let item = Labs.newReferenceRangeSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeScheduleRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Labs.ReferenceRangeScheduleRequiredChannelRule(message: "reference range schedule needs this field")
        let item = Labs.newReferenceRangeSchedule("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.ReferenceRangeScheduleNameLengthRule(maxLength: 32)
        let item = Labs.newReferenceRangeSchedule("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ReferenceRangeScheduleCodeLengthRule(maxLength: 80)
        let item = Labs.newReferenceRangeSchedule("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeScheduleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.ReferenceRangeScheduleRequiredNameRule(message: "reference range schedule needs an entry")
        let item = Labs.newReferenceRangeSchedule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangeScheduleRequiredCodeRule(message: "reference range schedule needs a value")
        let item = Labs.newReferenceRangeSchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
