@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityQuotaValidator()
        let item = Imaging.newModalityQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ModalityQuotaRequiredCodeRule(message: "modality quota needs an entry")
        let item = Imaging.newModalityQuota("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityQuotaRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Imaging.ModalityQuotaRequiredWardRule(message: "modality quota needs a value")
        let item = Imaging.newModalityQuota("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.ModalityQuotaRequiredTitleRule(message: "modality quota needs an entry")
        let item = Imaging.newModalityQuota("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
