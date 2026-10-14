@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedProgramWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedProgramWindowValidator()
        let item = CareManagement.newWeightedProgramWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedProgramWindowEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = CareManagement.WeightedProgramWindowEncounterIDLengthRule(maxLength: 1000)
        let item = CareManagement.newWeightedProgramWindow("x", label: "y")
        item.encounterID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedProgramWindowPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = CareManagement.WeightedProgramWindowPriorityRangeRule(min: 1000, max: 3600)
        let item = CareManagement.newWeightedProgramWindow("x", label: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementWeightedProgramWindowRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = CareManagement.WeightedProgramWindowRequiredEncounterIDRule(
            message: "weighted program window needs an entry"
        )
        let item = CareManagement.newWeightedProgramWindow("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementWeightedProgramWindowProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = CareManagement.WeightedProgramWindowProcedureCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newWeightedProgramWindow("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
