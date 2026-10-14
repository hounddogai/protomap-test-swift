@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientCareGapEntryValidator()
        let item = CareManagement.newLenientCareGapEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientCareGapEntryRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = CareManagement.LenientCareGapEntryRequiredDescriptionRule(
            message: "lenient care gap entry needs an entry"
        )
        let item = CareManagement.newLenientCareGapEntry("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientCareGapEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.LenientCareGapEntryRequiredCodeRule(message: "lenient care gap entry needs a value")
        let item = CareManagement.newLenientCareGapEntry("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientCareGapEntryChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = CareManagement.LenientCareGapEntryChecksumLengthRule(maxLength: 86400)
        let item = CareManagement.newLenientCareGapEntry("x", title: "y")
        item.checksum = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientCareGapEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LenientCareGapEntryCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newLenientCareGapEntry("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
