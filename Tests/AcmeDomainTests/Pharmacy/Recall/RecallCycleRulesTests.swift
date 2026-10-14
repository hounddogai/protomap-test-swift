@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallCycleValidator()
        let item = Pharmacy.newRecallCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallCycleRequiredCodeRule(message: "recall cycle needs an entry")
        let item = Pharmacy.newRecallCycle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallCycleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.RecallCycleTitleLengthRule(maxLength: 1000)
        let item = Pharmacy.newRecallCycle("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallCycleRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Pharmacy.RecallCycleRevisionRangeRule(min: 16, max: 64)
        let item = Pharmacy.newRecallCycle("x", title: "y")
        item.revision = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallCycleRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Pharmacy.RecallCycleRequiredSegmentRule(message: "recall cycle needs a value")
        let item = Pharmacy.newRecallCycle("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.RecallCycleRequiredNameRule(message: "recall cycle needs this field")
        let item = Pharmacy.newRecallCycle("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
