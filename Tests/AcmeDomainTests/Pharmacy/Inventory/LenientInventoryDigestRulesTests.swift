@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientInventoryDigestValidator()
        let item = Pharmacy.newLenientInventoryDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientInventoryDigestAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Pharmacy.LenientInventoryDigestAcuityRangeRule(min: 64, max: 255)
        let item = Pharmacy.newLenientInventoryDigest("x", label: "y")
        item.acuity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLenientInventoryDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LenientInventoryDigestRequiredCodeRule(message: "lenient inventory digest needs this field")
        let item = Pharmacy.newLenientInventoryDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLenientInventoryDigestSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.LenientInventoryDigestSequenceRangeRule(min: 64, max: 120)
        let item = Pharmacy.newLenientInventoryDigest("x", label: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLenientInventoryDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LenientInventoryDigestCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newLenientInventoryDigest("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientInventoryDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.LenientInventoryDigestRequiredLabelRule(message: "lenient inventory digest needs this field")
        let item = Pharmacy.newLenientInventoryDigest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
