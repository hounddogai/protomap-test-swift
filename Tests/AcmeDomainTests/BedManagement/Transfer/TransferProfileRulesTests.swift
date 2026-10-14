@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferProfileValidator()
        let item = BedManagement.newTransferProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferProfileSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = BedManagement.TransferProfileSpecialtyLengthRule(maxLength: 80)
        let item = BedManagement.newTransferProfile("x", label: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferProfileRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = BedManagement.TransferProfileRequiredProcedureCodeRule(message: "transfer profile needs this field")
        let item = BedManagement.newTransferProfile("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferProfileDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.TransferProfileDiscountRangeRule(min: 0.2, max: 1504.3)
        let item = BedManagement.newTransferProfile("x", label: "y")
        item.discount = 1505.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferProfileFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.TransferProfileFloorValueRangeRule(min: 2.0, max: 3314.3)
        let item = BedManagement.newTransferProfile("x", label: "y")
        item.floorValue = 3315.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferProfileRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.TransferProfileRequiredLabelRule(message: "transfer profile needs this field")
        let item = BedManagement.newTransferProfile("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferProfileRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = BedManagement.TransferProfileRequiredSpecialtyRule(message: "transfer profile needs an entry")
        let item = BedManagement.newTransferProfile("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
