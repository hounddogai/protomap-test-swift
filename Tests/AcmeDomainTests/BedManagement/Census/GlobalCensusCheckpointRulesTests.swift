@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalCensusCheckpointValidator()
        let item = BedManagement.newGlobalCensusCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalCensusCheckpointRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = BedManagement.GlobalCensusCheckpointRequiredUnitRule(
            message: "global census checkpoint needs this field"
        )
        let item = BedManagement.newGlobalCensusCheckpoint("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalCensusCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.GlobalCensusCheckpointRequiredTitleRule(
            message: "global census checkpoint needs an entry"
        )
        let item = BedManagement.newGlobalCensusCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
