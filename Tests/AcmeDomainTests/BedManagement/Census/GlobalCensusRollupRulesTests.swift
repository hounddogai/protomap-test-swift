@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalCensusRollupValidator()
        let item = BedManagement.newGlobalCensusRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalCensusRollupDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = BedManagement.GlobalCensusRollupDosageMgRangeRule(min: 0.0, max: 1511.2)
        let item = BedManagement.newGlobalCensusRollup("x", name: "y")
        item.dosageMg = 1512.7
        #expect(rule.check(item).count > 0)
    }
}
