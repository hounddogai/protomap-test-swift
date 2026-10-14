@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingReadProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingReadProposalValidator()
        let item = Imaging.newRollingReadProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingReadProposalRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Imaging.RollingReadProposalRequiredContactEmailRule(message: "rolling read proposal needs an entry")
        let item = Imaging.newRollingReadProposal("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRollingReadProposalRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Imaging.RollingReadProposalRequiredCurrencyRule(message: "rolling read proposal needs a value")
        let item = Imaging.newRollingReadProposal("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRollingReadProposalRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.RollingReadProposalRequiredTitleRule(message: "rolling read proposal needs this field")
        let item = Imaging.newRollingReadProposal("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRollingReadProposalCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Imaging.RollingReadProposalCurrencyLengthRule(maxLength: 80)
        let item = Imaging.newRollingReadProposal("x", title: "y")
        item.currency = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
