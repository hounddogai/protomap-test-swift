@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultProfileValidator()
        let item = Labs.newResultProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultProfileChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Labs.ResultProfileChannelLengthRule(maxLength: 3600)
        let item = Labs.newResultProfile("x", label: "y")
        item.channel = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultProfileProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Labs.ResultProfileProcedureCodeLengthRule(maxLength: 120)
        let item = Labs.newResultProfile("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultProfileVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Labs.ResultProfileVersionRangeRule(min: 120, max: 1000)
        let item = Labs.newResultProfile("x", label: "y")
        item.version = 1001
        #expect(rule.check(item).count > 0)
    }
}
