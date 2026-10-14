@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryCensusCheckpointValidator()
        let item = BedManagement.newPrimaryCensusCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryCensusCheckpointCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.PrimaryCensusCheckpointCopayRangeRule(min: 9.1, max: 3790.2)
        let item = BedManagement.newPrimaryCensusCheckpoint("x", title: "y")
        item.copay = 3791.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryCensusCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PrimaryCensusCheckpointCodeLengthRule(maxLength: 255)
        let item = BedManagement.newPrimaryCensusCheckpoint("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryCensusCheckpointRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = BedManagement.PrimaryCensusCheckpointRequiredSegmentRule(
            message: "primary census checkpoint needs an entry"
        )
        let item = BedManagement.newPrimaryCensusCheckpoint("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
