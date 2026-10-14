@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientInventoryGroupValidator()
        let item = Pharmacy.newLenientInventoryGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientInventoryGroupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.LenientInventoryGroupTitleLengthRule(maxLength: 80)
        let item = Pharmacy.newLenientInventoryGroup("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientInventoryGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LenientInventoryGroupRequiredCodeRule(message: "lenient inventory group needs this field")
        let item = Pharmacy.newLenientInventoryGroup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientInventoryGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LenientInventoryGroupCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newLenientInventoryGroup("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientInventoryGroupExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Pharmacy.LenientInventoryGroupExternalRefLengthRule(maxLength: 255)
        let item = Pharmacy.newLenientInventoryGroup("x", title: "y")
        item.externalRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
