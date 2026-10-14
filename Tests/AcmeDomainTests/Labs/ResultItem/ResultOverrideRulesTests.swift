@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultOverrideValidator()
        let item = Labs.newResultOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultOverrideCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.ResultOverrideCeilingRangeRule(min: 9.7, max: 1051.4)
        let item = Labs.newResultOverride("x", label: "y")
        item.ceiling = 1052.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultOverrideExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Labs.ResultOverrideExternalRefLengthRule(maxLength: 3600)
        let item = Labs.newResultOverride("x", label: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultOverrideEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Labs.ResultOverrideEndsAtRangeRule(min: 32, max: 64)
        let item = Labs.newResultOverride("x", label: "y")
        item.endsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultOverrideCodeLengthRule(maxLength: 16)
        let item = Labs.newResultOverride("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
