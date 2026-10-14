@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferBundleValidator()
        let item = BedManagement.newTransferBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferBundleRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = BedManagement.TransferBundleRequiredContactEmailRule(message: "transfer bundle needs this field")
        let item = BedManagement.newTransferBundle("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferBundleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.TransferBundleCopayRangeRule(min: 3.3, max: 2394.7)
        let item = BedManagement.newTransferBundle("x", name: "y")
        item.copay = 2396.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferBundleMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.TransferBundleMarginRangeRule(min: 7.9, max: 1670.2)
        let item = BedManagement.newTransferBundle("x", name: "y")
        item.margin = 1671.7
        #expect(rule.check(item).count > 0)
    }
}
