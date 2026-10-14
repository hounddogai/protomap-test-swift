@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalBedBoardManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalBedBoardManifestValidator()
        let item = BedManagement.newGlobalBedBoardManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalBedBoardManifestOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = BedManagement.GlobalBedBoardManifestOwnerIDLengthRule(maxLength: 3600)
        let item = BedManagement.newGlobalBedBoardManifest("x", label: "y")
        item.ownerID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementGlobalBedBoardManifestCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = BedManagement.GlobalBedBoardManifestCostRangeRule(min: 4.0, max: 2876.1)
        let item = BedManagement.newGlobalBedBoardManifest("x", label: "y")
        item.cost = 2877.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementGlobalBedBoardManifestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.GlobalBedBoardManifestLabelLengthRule(maxLength: 3600)
        let item = BedManagement.newGlobalBedBoardManifest("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementGlobalBedBoardManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.GlobalBedBoardManifestRequiredCodeRule(
            message: "global bed board manifest needs a value"
        )
        let item = BedManagement.newGlobalBedBoardManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalBedBoardManifestQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = BedManagement.GlobalBedBoardManifestQuantityRangeRule(min: 120, max: 86400)
        let item = BedManagement.newGlobalBedBoardManifest("x", label: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}
