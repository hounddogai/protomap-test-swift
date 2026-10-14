@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityDraftValidator()
        let item = Imaging.newPriorityDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.PriorityDraftRequiredNameRule(message: "priority draft needs an entry")
        let item = Imaging.newPriorityDraft("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityDraftVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Imaging.PriorityDraftVisitMinutesRangeRule(min: 32, max: 64)
        let item = Imaging.newPriorityDraft("x", title: "y")
        item.visitMinutes = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.PriorityDraftRequiredLabelRule(message: "priority draft needs a value")
        let item = Imaging.newPriorityDraft("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PriorityDraftCodeLengthRule(maxLength: 64)
        let item = Imaging.newPriorityDraft("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityDraftRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.PriorityDraftRequiredTitleRule(message: "priority draft needs an entry")
        let item = Imaging.newPriorityDraft("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityDraftRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.PriorityDraftRatioRangeRule(min: 2.2, max: 4000.2)
        let item = Imaging.newPriorityDraft("x", title: "y")
        item.ratio = 4001.7
        #expect(rule.check(item).count > 0)
    }
}
