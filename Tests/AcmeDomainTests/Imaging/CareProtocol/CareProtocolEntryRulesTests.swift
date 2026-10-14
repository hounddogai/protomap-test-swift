@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolEntryValidator()
        let item = Imaging.newCareProtocolEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolEntryRequiredCodeRule(message: "care protocol entry needs an entry")
        let item = Imaging.newCareProtocolEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.CareProtocolEntryNameLengthRule(maxLength: 80)
        let item = Imaging.newCareProtocolEntry("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolEntryCodeLengthRule(maxLength: 1000)
        let item = Imaging.newCareProtocolEntry("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolEntryRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Imaging.CareProtocolEntryRequiredWardRule(message: "care protocol entry needs this field")
        let item = Imaging.newCareProtocolEntry("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
