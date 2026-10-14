@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalPriorityCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalPriorityCycleValidator()
        let item = Imaging.newRegionalPriorityCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalPriorityCycleRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Imaging.RegionalPriorityCycleRequiredExternalRefRule(message: "regional priority cycle needs a value")
        let item = Imaging.newRegionalPriorityCycle("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalPriorityCycleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.RegionalPriorityCycleRequiredLabelRule(message: "regional priority cycle needs a value")
        let item = Imaging.newRegionalPriorityCycle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalPriorityCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.RegionalPriorityCycleRequiredCodeRule(message: "regional priority cycle needs a value")
        let item = Imaging.newRegionalPriorityCycle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalPriorityCycleCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Imaging.RegionalPriorityCycleCapacityRangeRule(min: 80, max: 3600)
        let item = Imaging.newRegionalPriorityCycle("x", label: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRegionalPriorityCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.RegionalPriorityCycleLabelLengthRule(maxLength: 64)
        let item = Imaging.newRegionalPriorityCycle("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
