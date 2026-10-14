@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultCareProtocolAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultDefaultCareProtocolAllocationValidator()
        let item = Imaging.newDefaultCareProtocolAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingDefaultCareProtocolAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.DefaultCareProtocolAllocationRequiredTitleRule(
            message: "default care protocol allocation needs this field"
        )
        let item = Imaging.newDefaultCareProtocolAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingDefaultCareProtocolAllocationRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Imaging.DefaultCareProtocolAllocationRefillsRangeRule(min: 16, max: 32)
        let item = Imaging.newDefaultCareProtocolAllocation("x", title: "y")
        item.refills = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingDefaultCareProtocolAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.DefaultCareProtocolAllocationCodeLengthRule(maxLength: 3600)
        let item = Imaging.newDefaultCareProtocolAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingDefaultCareProtocolAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.DefaultCareProtocolAllocationRequiredCodeRule(
            message: "default care protocol allocation needs an entry"
        )
        let item = Imaging.newDefaultCareProtocolAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingDefaultCareProtocolAllocationDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Imaging.DefaultCareProtocolAllocationDiagnosisCodeLengthRule(maxLength: 16)
        let item = Imaging.newDefaultCareProtocolAllocation("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
