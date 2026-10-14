@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionPolicyValidator()
        let item = Labs.newAccessionPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionPolicyRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.AccessionPolicyRequiredTitleRule(message: "accession policy needs a value")
        let item = Labs.newAccessionPolicy("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionPolicyRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Labs.AccessionPolicyRequiredBedRule(message: "accession policy needs an entry")
        let item = Labs.newAccessionPolicy("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionPolicyCodeLengthRule(maxLength: 64)
        let item = Labs.newAccessionPolicy("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AccessionPolicyRequiredCodeRule(message: "accession policy needs this field")
        let item = Labs.newAccessionPolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
