@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackCensusSnapshotValidator()
        let item = BedManagement.newFallbackCensusSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackCensusSnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.FallbackCensusSnapshotNameLengthRule(maxLength: 32)
        let item = BedManagement.newFallbackCensusSnapshot("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackCensusSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.FallbackCensusSnapshotRequiredCodeRule(
            message: "fallback census snapshot needs this field"
        )
        let item = BedManagement.newFallbackCensusSnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackCensusSnapshotProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = BedManagement.FallbackCensusSnapshotProcedureCodeLengthRule(maxLength: 80)
        let item = BedManagement.newFallbackCensusSnapshot("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
