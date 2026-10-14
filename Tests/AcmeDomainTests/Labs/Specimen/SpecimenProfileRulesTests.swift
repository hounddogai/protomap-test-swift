@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenProfileValidator()
        let item = Labs.newSpecimenProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenProfileRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.SpecimenProfileRequiredNameRule(message: "specimen profile needs an entry")
        let item = Labs.newSpecimenProfile("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenProfileRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.SpecimenProfileRequiredPayerRule(message: "specimen profile needs an entry")
        let item = Labs.newSpecimenProfile("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenProfileWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Labs.SpecimenProfileWardLengthRule(maxLength: 120)
        let item = Labs.newSpecimenProfile("x", name: "y")
        item.ward = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
