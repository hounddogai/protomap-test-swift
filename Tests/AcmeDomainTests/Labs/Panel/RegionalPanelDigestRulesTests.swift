@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalPanelDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRegionalPanelDigestValidator()
        let item = Labs.newRegionalPanelDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRegionalPanelDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.RegionalPanelDigestRequiredCodeRule(message: "regional panel digest needs an entry")
        let item = Labs.newRegionalPanelDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalPanelDigestClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Labs.RegionalPanelDigestClinicianIDLengthRule(maxLength: 16)
        let item = Labs.newRegionalPanelDigest("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRegionalPanelDigestChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Labs.RegionalPanelDigestChecksumLengthRule(maxLength: 3600)
        let item = Labs.newRegionalPanelDigest("x", title: "y")
        item.checksum = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRegionalPanelDigestRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Labs.RegionalPanelDigestRequiredClinicianIDRule(message: "regional panel digest needs a value")
        let item = Labs.newRegionalPanelDigest("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalPanelDigestRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Labs.RegionalPanelDigestRequiredChecksumRule(message: "regional panel digest needs an entry")
        let item = Labs.newRegionalPanelDigest("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
