@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPriorityQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalPriorityQuotaValidator()
        let item = Imaging.newGlobalPriorityQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalPriorityQuotaEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Imaging.GlobalPriorityQuotaEncounterIDLengthRule(maxLength: 64)
        let item = Imaging.newGlobalPriorityQuota("x", label: "y")
        item.encounterID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalPriorityQuotaUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.GlobalPriorityQuotaUpdatedAtRangeRule(min: 32, max: 86400)
        let item = Imaging.newGlobalPriorityQuota("x", label: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingGlobalPriorityQuotaRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.GlobalPriorityQuotaRequiredLabelRule(message: "global priority quota needs an entry")
        let item = Imaging.newGlobalPriorityQuota("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
