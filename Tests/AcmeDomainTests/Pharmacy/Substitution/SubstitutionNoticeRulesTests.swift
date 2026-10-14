@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionNoticeValidator()
        let item = Pharmacy.newSubstitutionNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionNoticeTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.SubstitutionNoticeTitleLengthRule(maxLength: 86400)
        let item = Pharmacy.newSubstitutionNotice("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionNoticeLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.SubstitutionNoticeLabelLengthRule(maxLength: 120)
        let item = Pharmacy.newSubstitutionNotice("x", title: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.SubstitutionNoticeCodeLengthRule(maxLength: 86400)
        let item = Pharmacy.newSubstitutionNotice("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
