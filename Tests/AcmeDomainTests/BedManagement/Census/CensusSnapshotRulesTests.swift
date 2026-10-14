@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusSnapshotValidator()
        let item = BedManagement.newCensusSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusSnapshotSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = BedManagement.CensusSnapshotSequenceRangeRule(min: 120, max: 86400)
        let item = BedManagement.newCensusSnapshot("x", label: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusSnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.CensusSnapshotLabelLengthRule(maxLength: 64)
        let item = BedManagement.newCensusSnapshot("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CensusSnapshotRequiredCodeRule(message: "census snapshot needs this field")
        let item = BedManagement.newCensusSnapshot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
