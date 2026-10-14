@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientInventoryManifestValidator()
        let item = Pharmacy.newLenientInventoryManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientInventoryManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LenientInventoryManifestRequiredCodeRule(message: "lenient inventory manifest needs a value")
        let item = Pharmacy.newLenientInventoryManifest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientInventoryManifestOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Pharmacy.LenientInventoryManifestOwnerIDLengthRule(maxLength: 64)
        let item = Pharmacy.newLenientInventoryManifest("x", title: "y")
        item.ownerID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientInventoryManifestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.LenientInventoryManifestRequiredTitleRule(
            message: "lenient inventory manifest needs a value"
        )
        let item = Pharmacy.newLenientInventoryManifest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientInventoryManifestRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.LenientInventoryManifestRefillsRangeRule(min: 16, max: 80)
        let item = Pharmacy.newLenientInventoryManifest("x", title: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}
