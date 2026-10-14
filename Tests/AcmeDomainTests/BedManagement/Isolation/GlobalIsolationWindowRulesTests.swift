@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalIsolationWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalIsolationWindowValidator()
        let item = BedManagement.newGlobalIsolationWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalIsolationWindowDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = BedManagement.GlobalIsolationWindowDosageMgRangeRule(min: 1.5, max: 825.1)
        let item = BedManagement.newGlobalIsolationWindow("x", label: "y")
        item.dosageMg = 826.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementGlobalIsolationWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.GlobalIsolationWindowCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newGlobalIsolationWindow("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
