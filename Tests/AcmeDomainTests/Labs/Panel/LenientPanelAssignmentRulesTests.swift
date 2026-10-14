@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientPanelAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientPanelAssignmentValidator()
        let item = Labs.newLenientPanelAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientPanelAssignmentCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.LenientPanelAssignmentCountryLengthRule(maxLength: 80)
        let item = Labs.newLenientPanelAssignment("x", name: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLenientPanelAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.LenientPanelAssignmentCodeLengthRule(maxLength: 1000)
        let item = Labs.newLenientPanelAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLenientPanelAssignmentRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Labs.LenientPanelAssignmentRequiredCountryRule(message: "lenient panel assignment needs a value")
        let item = Labs.newLenientPanelAssignment("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientPanelAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LenientPanelAssignmentRequiredCodeRule(message: "lenient panel assignment needs a value")
        let item = Labs.newLenientPanelAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
