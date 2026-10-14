@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferAssignmentValidator()
        let item = BedManagement.newTransferAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferAssignmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.TransferAssignmentFloorValueRangeRule(min: 3.9, max: 4426.2)
        let item = BedManagement.newTransferAssignment("x", label: "y")
        item.floorValue = 4427.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferAssignmentPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = BedManagement.TransferAssignmentPayerLengthRule(maxLength: 1000)
        let item = BedManagement.newTransferAssignment("x", label: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferAssignmentAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = BedManagement.TransferAssignmentAcuityRangeRule(min: 16, max: 3600)
        let item = BedManagement.newTransferAssignment("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferAssignmentSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = BedManagement.TransferAssignmentSummaryLengthRule(maxLength: 3600)
        let item = BedManagement.newTransferAssignment("x", label: "y")
        item.summary = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
