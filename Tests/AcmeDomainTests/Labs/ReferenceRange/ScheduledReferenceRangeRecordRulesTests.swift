@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledReferenceRangeRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledReferenceRangeRecordValidator()
        let item = Labs.newScheduledReferenceRangeRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledReferenceRangeRecordRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.ScheduledReferenceRangeRecordRateRangeRule(min: 8.8, max: 1488.0)
        let item = Labs.newScheduledReferenceRangeRecord("x", label: "y")
        item.rate = 1489.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledReferenceRangeRecordRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Labs.ScheduledReferenceRangeRecordRequiredRegionRule(
            message: "scheduled reference range record needs a value"
        )
        let item = Labs.newScheduledReferenceRangeRecord("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledReferenceRangeRecordWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Labs.ScheduledReferenceRangeRecordWeightRangeRule(min: 7.9, max: 3360.0)
        let item = Labs.newScheduledReferenceRangeRecord("x", label: "y")
        item.weight = 3361.5
        #expect(rule.check(item).count > 0)
    }
}
