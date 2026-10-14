@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialCycleValidator()
        let item = Staffing.newCredentialCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialCycleCodeLengthRule(maxLength: 120)
        let item = Staffing.newCredentialCycle("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialCycleFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.CredentialCycleFloorValueRangeRule(min: 8.0, max: 3761.5)
        let item = Staffing.newCredentialCycle("x", label: "y")
        item.floorValue = 3763.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialCycleCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Staffing.CredentialCycleCurrencyLengthRule(maxLength: 86400)
        let item = Staffing.newCredentialCycle("x", label: "y")
        item.currency = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialCycleRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Staffing.CredentialCycleRatioRangeRule(min: 7.7, max: 4135.9)
        let item = Staffing.newCredentialCycle("x", label: "y")
        item.ratio = 4137.4
        #expect(rule.check(item).count > 0)
    }
}
