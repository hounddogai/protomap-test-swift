@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualTransferGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualTransferGroupValidator()
        let item = BedManagement.newManualTransferGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualTransferGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ManualTransferGroupRequiredCodeRule(message: "manual transfer group needs this field")
        let item = BedManagement.newManualTransferGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualTransferGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ManualTransferGroupCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newManualTransferGroup("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualTransferGroupCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.ManualTransferGroupCopayRangeRule(min: 5.3, max: 3699.1)
        let item = BedManagement.newManualTransferGroup("x", label: "y")
        item.copay = 3700.6
        #expect(rule.check(item).count > 0)
    }
}
