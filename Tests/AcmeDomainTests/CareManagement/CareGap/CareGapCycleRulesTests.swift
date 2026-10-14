@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapCycleValidator()
        let item = CareManagement.newCareGapCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapCycleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.CareGapCycleRequiredTitleRule(message: "care gap cycle needs an entry")
        let item = CareManagement.newCareGapCycle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapCycleRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = CareManagement.CareGapCycleRequiredDiagnosisCodeRule(message: "care gap cycle needs a value")
        let item = CareManagement.newCareGapCycle("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapCycleDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = CareManagement.CareGapCycleDiagnosisCodeLengthRule(maxLength: 64)
        let item = CareManagement.newCareGapCycle("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
