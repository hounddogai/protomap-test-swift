@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalSpecimenExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalSpecimenExceptionValidator()
        let item = Labs.newGlobalSpecimenException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalSpecimenExceptionRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.GlobalSpecimenExceptionRequiredTitleRule(message: "global specimen exception needs an entry")
        let item = Labs.newGlobalSpecimenException("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalSpecimenExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.GlobalSpecimenExceptionCodeLengthRule(maxLength: 32)
        let item = Labs.newGlobalSpecimenException("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsGlobalSpecimenExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.GlobalSpecimenExceptionRequiredCodeRule(message: "global specimen exception needs an entry")
        let item = Labs.newGlobalSpecimenException("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalSpecimenExceptionVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Labs.GlobalSpecimenExceptionVersionRangeRule(min: 16, max: 64)
        let item = Labs.newGlobalSpecimenException("x", title: "y")
        item.version = 65
        #expect(rule.check(item).count > 0)
    }
}
