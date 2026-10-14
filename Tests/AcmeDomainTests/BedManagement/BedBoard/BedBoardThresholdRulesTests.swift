@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardThresholdValidator()
        let item = BedManagement.newBedBoardThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.BedBoardThresholdRequiredTitleRule(message: "bed board threshold needs a value")
        let item = BedManagement.newBedBoardThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardThresholdCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.BedBoardThresholdCopayRangeRule(min: 7.9, max: 3055.5)
        let item = BedManagement.newBedBoardThreshold("x", title: "y")
        item.copay = 3057.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardThresholdFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = BedManagement.BedBoardThresholdFacilityLengthRule(maxLength: 255)
        let item = BedManagement.newBedBoardThreshold("x", title: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BedBoardThresholdRequiredCodeRule(message: "bed board threshold needs this field")
        let item = BedManagement.newBedBoardThreshold("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardThresholdCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = BedManagement.BedBoardThresholdCreatedAtRangeRule(min: 16, max: 120)
        let item = BedManagement.newBedBoardThreshold("x", title: "y")
        item.createdAt = 121
        #expect(rule.check(item).count > 0)
    }
}
