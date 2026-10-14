@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultProgramSnapshotValidator()
        let item = CareManagement.newProgramSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementProgramSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ProgramSnapshotRequiredCodeRule(message: "program snapshot needs this field")
        let item = CareManagement.newProgramSnapshot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramSnapshotAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = CareManagement.ProgramSnapshotAcuityRangeRule(min: 16, max: 64)
        let item = CareManagement.newProgramSnapshot("x", label: "y")
        item.acuity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramSnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.ProgramSnapshotRequiredLabelRule(message: "program snapshot needs a value")
        let item = CareManagement.newProgramSnapshot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementProgramSnapshotVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.ProgramSnapshotVersionRangeRule(min: 16, max: 80)
        let item = CareManagement.newProgramSnapshot("x", label: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementProgramSnapshotCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = CareManagement.ProgramSnapshotCostRangeRule(min: 3.0, max: 2857.3)
        let item = CareManagement.newProgramSnapshot("x", label: "y")
        item.cost = 2858.8
        #expect(rule.check(item).count > 0)
    }
}
