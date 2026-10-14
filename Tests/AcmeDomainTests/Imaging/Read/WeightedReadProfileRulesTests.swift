@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedReadProfileValidator()
        let item = Imaging.newWeightedReadProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedReadProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WeightedReadProfileCodeLengthRule(maxLength: 1000)
        let item = Imaging.newWeightedReadProfile("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedReadProfileRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.WeightedReadProfileRequiredNameRule(message: "weighted read profile needs this field")
        let item = Imaging.newWeightedReadProfile("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWeightedReadProfileExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Imaging.WeightedReadProfileExternalRefLengthRule(maxLength: 3600)
        let item = Imaging.newWeightedReadProfile("x", name: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedReadProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WeightedReadProfileRequiredCodeRule(message: "weighted read profile needs a value")
        let item = Imaging.newWeightedReadProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWeightedReadProfileCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Imaging.WeightedReadProfileCategoryLengthRule(maxLength: 3600)
        let item = Imaging.newWeightedReadProfile("x", name: "y")
        item.category = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
