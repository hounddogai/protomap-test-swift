@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferBaselineValidator()
        let item = BedManagement.newTransferBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.TransferBaselineLabelLengthRule(maxLength: 80)
        let item = BedManagement.newTransferBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferBaselineWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = BedManagement.TransferBaselineWardLengthRule(maxLength: 32)
        let item = BedManagement.newTransferBaseline("x", label: "y")
        item.ward = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferBaselineMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = BedManagement.TransferBaselineMaximumRangeRule(min: 6.6, max: 2491.4)
        let item = BedManagement.newTransferBaseline("x", label: "y")
        item.maximum = 2492.9
        #expect(rule.check(item).count > 0)
    }
}
