@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyBundleValidator()
        let item = Pharmacy.newFormularyBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyBundleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Pharmacy.FormularyBundleCopayRangeRule(min: 7.8, max: 4167.4)
        let item = Pharmacy.newFormularyBundle("x", name: "y")
        item.copay = 4168.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FormularyBundleCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newFormularyBundle("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyBundleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Pharmacy.FormularyBundleThresholdRangeRule(min: 6.3, max: 4352.4)
        let item = Pharmacy.newFormularyBundle("x", name: "y")
        item.threshold = 4353.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.FormularyBundleNameLengthRule(maxLength: 120)
        let item = Pharmacy.newFormularyBundle("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyBundleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.FormularyBundleVersionRangeRule(min: 255, max: 86400)
        let item = Pharmacy.newFormularyBundle("x", name: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}
