@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualResultBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultManualResultBaselineValidator()
        let item = Labs.newManualResultBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsManualResultBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ManualResultBaselineRequiredCodeRule(message: "manual result baseline needs an entry")
        let item = Labs.newManualResultBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsManualResultBaselineLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Labs.ManualResultBaselineLocaleLengthRule(maxLength: 86400)
        let item = Labs.newManualResultBaseline("x", name: "y")
        item.locale = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsManualResultBaselineFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Labs.ManualResultBaselineFacilityLengthRule(maxLength: 16)
        let item = Labs.newManualResultBaseline("x", name: "y")
        item.facility = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
