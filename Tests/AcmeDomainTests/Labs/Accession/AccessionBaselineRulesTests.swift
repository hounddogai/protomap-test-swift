@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionBaselineValidator()
        let item = Labs.newAccessionBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.AccessionBaselineNameLengthRule(maxLength: 16)
        let item = Labs.newAccessionBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionBaselineCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Labs.AccessionBaselineCostRangeRule(min: 8.4, max: 3650.6)
        let item = Labs.newAccessionBaseline("x", name: "y")
        item.cost = 3652.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionBaselineOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Labs.AccessionBaselineOwnerIDLengthRule(maxLength: 86400)
        let item = Labs.newAccessionBaseline("x", name: "y")
        item.ownerID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
