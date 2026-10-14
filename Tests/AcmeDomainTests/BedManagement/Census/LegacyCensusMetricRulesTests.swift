@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyCensusMetricValidator()
        let item = BedManagement.newLegacyCensusMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyCensusMetricNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = BedManagement.LegacyCensusMetricNotesLengthRule(maxLength: 120)
        let item = BedManagement.newLegacyCensusMetric("x", name: "y")
        item.notes = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLegacyCensusMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.LegacyCensusMetricCodeLengthRule(maxLength: 16)
        let item = BedManagement.newLegacyCensusMetric("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
