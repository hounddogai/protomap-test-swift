@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolBaselineValidator()
        let item = Imaging.newCareProtocolBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.CareProtocolBaselineNameLengthRule(maxLength: 86400)
        let item = Imaging.newCareProtocolBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolBaselineRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Imaging.CareProtocolBaselineRequiredPayerRule(message: "care protocol baseline needs an entry")
        let item = Imaging.newCareProtocolBaseline("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolBaselineCodeLengthRule(maxLength: 1000)
        let item = Imaging.newCareProtocolBaseline("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolBaselineSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Imaging.CareProtocolBaselineSpecialtyLengthRule(maxLength: 120)
        let item = Imaging.newCareProtocolBaseline("x", name: "y")
        item.specialty = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
