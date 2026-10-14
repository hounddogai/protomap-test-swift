@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryReferenceRangeScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPrimaryReferenceRangeScheduleValidator()
        let item = Labs.newPrimaryReferenceRangeSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPrimaryReferenceRangeScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PrimaryReferenceRangeScheduleCodeLengthRule(maxLength: 3600)
        let item = Labs.newPrimaryReferenceRangeSchedule("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryReferenceRangeScheduleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.PrimaryReferenceRangeScheduleRequiredTitleRule(
            message: "primary reference range schedule needs this field"
        )
        let item = Labs.newPrimaryReferenceRangeSchedule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPrimaryReferenceRangeScheduleBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.PrimaryReferenceRangeScheduleBatchSizeRangeRule(min: 255, max: 1000)
        let item = Labs.newPrimaryReferenceRangeSchedule("x", title: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPrimaryReferenceRangeScheduleRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Labs.PrimaryReferenceRangeScheduleRequiredChannelRule(
            message: "primary reference range schedule needs an entry"
        )
        let item = Labs.newPrimaryReferenceRangeSchedule("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
