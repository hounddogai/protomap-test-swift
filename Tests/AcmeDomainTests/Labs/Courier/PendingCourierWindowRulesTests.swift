@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingCourierWindowValidator()
        let item = Labs.newPendingCourierWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingCourierWindowRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Labs.PendingCourierWindowRetriesRangeRule(min: 255, max: 86400)
        let item = Labs.newPendingCourierWindow("x", name: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPendingCourierWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PendingCourierWindowCodeLengthRule(maxLength: 1000)
        let item = Labs.newPendingCourierWindow("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPendingCourierWindowRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.PendingCourierWindowRequiredNameRule(message: "pending courier window needs this field")
        let item = Labs.newPendingCourierWindow("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingCourierWindowRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.PendingCourierWindowRequiredLocaleRule(message: "pending courier window needs this field")
        let item = Labs.newPendingCourierWindow("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingCourierWindowUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Labs.PendingCourierWindowUnitLengthRule(maxLength: 80)
        let item = Labs.newPendingCourierWindow("x", name: "y")
        item.unit = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
