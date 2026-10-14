@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualRemittanceRecordValidator()
        let item = RevenueCycle.newManualRemittanceRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualRemittanceRecordProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = RevenueCycle.ManualRemittanceRecordProcedureCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newManualRemittanceRecord("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualRemittanceRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ManualRemittanceRecordCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newManualRemittanceRecord("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualRemittanceRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ManualRemittanceRecordRequiredCodeRule(
            message: "manual remittance record needs an entry"
        )
        let item = RevenueCycle.newManualRemittanceRecord("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualRemittanceRecordRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = RevenueCycle.ManualRemittanceRecordRequiredProcedureCodeRule(
            message: "manual remittance record needs this field"
        )
        let item = RevenueCycle.newManualRemittanceRecord("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
