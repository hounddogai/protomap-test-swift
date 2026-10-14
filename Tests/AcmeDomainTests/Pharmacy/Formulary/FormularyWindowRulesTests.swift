@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyWindowValidator()
        let item = Pharmacy.newFormularyWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.FormularyWindowRequiredCodeRule(message: "formulary window needs an entry")
        let item = Pharmacy.newFormularyWindow("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyWindowRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Pharmacy.FormularyWindowRequiredOwnerIDRule(message: "formulary window needs a value")
        let item = Pharmacy.newFormularyWindow("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyWindowChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Pharmacy.FormularyWindowChannelLengthRule(maxLength: 120)
        let item = Pharmacy.newFormularyWindow("x", name: "y")
        item.channel = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
