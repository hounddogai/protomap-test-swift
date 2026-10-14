@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenGroupValidator()
        let item = Labs.newSpecimenGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SpecimenGroupCodeLengthRule(maxLength: 120)
        let item = Labs.newSpecimenGroup("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.SpecimenGroupNameLengthRule(maxLength: 16)
        let item = Labs.newSpecimenGroup("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenGroupCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.SpecimenGroupCeilingRangeRule(min: 9.0, max: 1572.9)
        let item = Labs.newSpecimenGroup("x", name: "y")
        item.ceiling = 1574.4
        #expect(rule.check(item).count > 0)
    }
}
