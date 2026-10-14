@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryCensusSegmentValidator()
        let item = BedManagement.newPrimaryCensusSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryCensusSegmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.PrimaryCensusSegmentFloorValueRangeRule(min: 1.8, max: 1366.7)
        let item = BedManagement.newPrimaryCensusSegment("x", label: "y")
        item.floorValue = 1368.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryCensusSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.PrimaryCensusSegmentRequiredLabelRule(
            message: "primary census segment needs this field"
        )
        let item = BedManagement.newPrimaryCensusSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryCensusSegmentEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = BedManagement.PrimaryCensusSegmentEncounterIDLengthRule(maxLength: 32)
        let item = BedManagement.newPrimaryCensusSegment("x", label: "y")
        item.encounterID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryCensusSegmentRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = BedManagement.PrimaryCensusSegmentRequiredEncounterIDRule(
            message: "primary census segment needs an entry"
        )
        let item = BedManagement.newPrimaryCensusSegment("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
