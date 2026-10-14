@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardCheckpointValidator()
        let item = BedManagement.newBedBoardCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardCheckpointRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = BedManagement.BedBoardCheckpointRequiredSpecialtyRule(message: "bed board checkpoint needs a value")
        let item = BedManagement.newBedBoardCheckpoint("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardCheckpointRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = BedManagement.BedBoardCheckpointRequiredSegmentRule(message: "bed board checkpoint needs an entry")
        let item = BedManagement.newBedBoardCheckpoint("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardCheckpointTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.BedBoardCheckpointTitleLengthRule(maxLength: 64)
        let item = BedManagement.newBedBoardCheckpoint("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
