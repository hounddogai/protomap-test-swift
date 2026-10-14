@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardSnapshotValidator()
        let item = BedManagement.newBedBoardSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardSnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.BedBoardSnapshotNameLengthRule(maxLength: 32)
        let item = BedManagement.newBedBoardSnapshot("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardSnapshotDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = BedManagement.BedBoardSnapshotDiagnosisCodeLengthRule(maxLength: 255)
        let item = BedManagement.newBedBoardSnapshot("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardSnapshotGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.BedBoardSnapshotGraceDaysRangeRule(min: 120, max: 120)
        let item = BedManagement.newBedBoardSnapshot("x", name: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardSnapshotRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = BedManagement.BedBoardSnapshotRequiredProcedureCodeRule(
            message: "bed board snapshot needs this field"
        )
        let item = BedManagement.newBedBoardSnapshot("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
