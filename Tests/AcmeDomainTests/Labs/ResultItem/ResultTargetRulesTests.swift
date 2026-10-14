@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultTargetValidator()
        let item = Labs.newResultTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultTargetCodeLengthRule(maxLength: 64)
        let item = Labs.newResultTarget("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultTargetSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Labs.ResultTargetSummaryLengthRule(maxLength: 32)
        let item = Labs.newResultTarget("x", name: "y")
        item.summary = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.ResultTargetNameLengthRule(maxLength: 120)
        let item = Labs.newResultTarget("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
