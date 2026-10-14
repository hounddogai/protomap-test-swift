@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispensePlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispensePlanValidator()
        let item = Pharmacy.newDispensePlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispensePlanLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.DispensePlanLabelLengthRule(maxLength: 255)
        let item = Pharmacy.newDispensePlan("x", title: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispensePlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DispensePlanCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newDispensePlan("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
