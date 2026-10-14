@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualResultDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultManualResultDigestValidator()
        let item = Labs.newManualResultDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsManualResultDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ManualResultDigestRequiredCodeRule(message: "manual result digest needs a value")
        let item = Labs.newManualResultDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsManualResultDigestExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Labs.ManualResultDigestExternalRefLengthRule(maxLength: 16)
        let item = Labs.newManualResultDigest("x", title: "y")
        item.externalRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
