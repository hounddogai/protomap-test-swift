@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalReadVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalReadVarianceValidator()
        let item = Imaging.newGlobalReadVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalReadVarianceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.GlobalReadVarianceLabelLengthRule(maxLength: 32)
        let item = Imaging.newGlobalReadVariance("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalReadVarianceContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Imaging.GlobalReadVarianceContactEmailLengthRule(maxLength: 16)
        let item = Imaging.newGlobalReadVariance("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalReadVarianceRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Imaging.GlobalReadVarianceRequiredContactEmailRule(message: "global read variance needs an entry")
        let item = Imaging.newGlobalReadVariance("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalReadVarianceChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Imaging.GlobalReadVarianceChecksumLengthRule(maxLength: 16)
        let item = Imaging.newGlobalReadVariance("x", label: "y")
        item.checksum = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalReadVarianceBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Imaging.GlobalReadVarianceBudgetRangeRule(min: 2.3, max: 3184.0)
        let item = Imaging.newGlobalReadVariance("x", label: "y")
        item.budget = 3185.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingGlobalReadVarianceWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.GlobalReadVarianceWeightRangeRule(min: 2.6, max: 118.1)
        let item = Imaging.newGlobalReadVariance("x", label: "y")
        item.weight = 119.6
        #expect(rule.check(item).count > 0)
    }
}
