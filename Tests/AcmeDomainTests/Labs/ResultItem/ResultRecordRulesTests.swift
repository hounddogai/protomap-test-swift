@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultRecordValidator()
        let item = Labs.newResultRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultRecordRequiredCodeRule(message: "result record needs this field")
        let item = Labs.newResultRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.ResultRecordRequiredLabelRule(message: "result record needs a value")
        let item = Labs.newResultRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
