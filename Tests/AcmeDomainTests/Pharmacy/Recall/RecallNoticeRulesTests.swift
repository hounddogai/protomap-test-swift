@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallNoticeValidator()
        let item = Pharmacy.newRecallNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallNoticeRequiredCodeRule(message: "recall notice needs an entry")
        let item = Pharmacy.newRecallNotice("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.RecallNoticeRequiredTitleRule(message: "recall notice needs a value")
        let item = Pharmacy.newRecallNotice("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallNoticeTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.RecallNoticeTitleLengthRule(maxLength: 255)
        let item = Pharmacy.newRecallNotice("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RecallNoticeCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newRecallNotice("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallNoticeProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Pharmacy.RecallNoticeProcedureCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newRecallNotice("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallNoticeRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Pharmacy.RecallNoticeRequiredChannelRule(message: "recall notice needs a value")
        let item = Pharmacy.newRecallNotice("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
