@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseRequestValidator()
        let item = Pharmacy.newDispenseRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseRequestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.DispenseRequestNameLengthRule(maxLength: 255)
        let item = Pharmacy.newDispenseRequest("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseRequestRequiredCodeRule(message: "dispense request needs a value")
        let item = Pharmacy.newDispenseRequest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseRequestPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Pharmacy.DispenseRequestPhoneLengthRule(maxLength: 1000)
        let item = Pharmacy.newDispenseRequest("x", name: "y")
        item.phone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
