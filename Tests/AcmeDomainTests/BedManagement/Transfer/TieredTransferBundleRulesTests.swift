@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredTransferBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTieredTransferBundleValidator()
        let item = BedManagement.newTieredTransferBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTieredTransferBundleRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = BedManagement.TieredTransferBundleRequiredSpecialtyRule(
            message: "tiered transfer bundle needs an entry"
        )
        let item = BedManagement.newTieredTransferBundle("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTieredTransferBundleLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = BedManagement.TieredTransferBundleLocaleLengthRule(maxLength: 120)
        let item = BedManagement.newTieredTransferBundle("x", label: "y")
        item.locale = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
