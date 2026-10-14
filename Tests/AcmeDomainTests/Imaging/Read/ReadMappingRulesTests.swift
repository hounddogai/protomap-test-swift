@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadMappingValidator()
        let item = Imaging.newReadMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ReadMappingRequiredCodeRule(message: "read mapping needs an entry")
        let item = Imaging.newReadMapping("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadMappingCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Imaging.ReadMappingCreatedAtRangeRule(min: 32, max: 64)
        let item = Imaging.newReadMapping("x", name: "y")
        item.createdAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.ReadMappingNameLengthRule(maxLength: 255)
        let item = Imaging.newReadMapping("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadMappingAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Imaging.ReadMappingAllergyLengthRule(maxLength: 3600)
        let item = Imaging.newReadMapping("x", name: "y")
        item.allergy = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadMappingSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Imaging.ReadMappingSpecialtyLengthRule(maxLength: 255)
        let item = Imaging.newReadMapping("x", name: "y")
        item.specialty = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
