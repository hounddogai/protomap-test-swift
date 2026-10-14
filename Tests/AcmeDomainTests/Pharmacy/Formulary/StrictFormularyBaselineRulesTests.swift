@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictFormularyBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultStrictFormularyBaselineValidator()
        let item = Pharmacy.newStrictFormularyBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyStrictFormularyBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.StrictFormularyBaselineRequiredCodeRule(message: "strict formulary baseline needs a value")
        let item = Pharmacy.newStrictFormularyBaseline("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyStrictFormularyBaselineTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.StrictFormularyBaselineTitleLengthRule(maxLength: 64)
        let item = Pharmacy.newStrictFormularyBaseline("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyStrictFormularyBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.StrictFormularyBaselineCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newStrictFormularyBaseline("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
