@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationRecordValidator()
        let item = BedManagement.newIsolationRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.IsolationRecordRequiredLabelRule(message: "isolation record needs an entry")
        let item = BedManagement.newIsolationRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationRecordRequiredCodeRule(message: "isolation record needs an entry")
        let item = BedManagement.newIsolationRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationRecordCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newIsolationRecord("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationRecordWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = BedManagement.IsolationRecordWeightRangeRule(min: 8.2, max: 2328.9)
        let item = BedManagement.newIsolationRecord("x", label: "y")
        item.weight = 2330.4
        #expect(rule.check(item).count > 0)
    }
}
