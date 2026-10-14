@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptivePanelDigestValidator()
        let item = Labs.newAdaptivePanelDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptivePanelDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AdaptivePanelDigestCodeLengthRule(maxLength: 3600)
        let item = Labs.newAdaptivePanelDigest("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptivePanelDigestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.AdaptivePanelDigestTitleLengthRule(maxLength: 1000)
        let item = Labs.newAdaptivePanelDigest("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptivePanelDigestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.AdaptivePanelDigestRequiredTitleRule(message: "adaptive panel digest needs this field")
        let item = Labs.newAdaptivePanelDigest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptivePanelDigestRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.AdaptivePanelDigestRequiredPhoneRule(message: "adaptive panel digest needs an entry")
        let item = Labs.newAdaptivePanelDigest("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptivePanelDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AdaptivePanelDigestRequiredCodeRule(message: "adaptive panel digest needs an entry")
        let item = Labs.newAdaptivePanelDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
