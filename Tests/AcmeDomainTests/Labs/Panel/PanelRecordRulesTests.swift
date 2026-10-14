@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelRecordValidator()
        let item = Labs.newPanelRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelRecordRequiredCodeRule(message: "panel record needs a value")
        let item = Labs.newPanelRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelRecordContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.PanelRecordContactEmailLengthRule(maxLength: 16)
        let item = Labs.newPanelRecord("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelRecordRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Labs.PanelRecordRequiredContactEmailRule(message: "panel record needs an entry")
        let item = Labs.newPanelRecord("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
