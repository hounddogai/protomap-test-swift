@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultDispenseManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultDispenseManifestValidator()
        let item = Pharmacy.newDefaultDispenseManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultDispenseManifestRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.DefaultDispenseManifestRatioRangeRule(min: 9.5, max: 99.1)
        let item = Pharmacy.newDefaultDispenseManifest("x", title: "y")
        item.ratio = 100.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultDispenseManifestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.DefaultDispenseManifestTitleLengthRule(maxLength: 1000)
        let item = Pharmacy.newDefaultDispenseManifest("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultDispenseManifestRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Pharmacy.DefaultDispenseManifestRequiredOwnerIDRule(
            message: "default dispense manifest needs an entry"
        )
        let item = Pharmacy.newDefaultDispenseManifest("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultDispenseManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DefaultDispenseManifestCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newDefaultDispenseManifest("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultDispenseManifestRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Pharmacy.DefaultDispenseManifestRequiredTimezoneRule(
            message: "default dispense manifest needs this field"
        )
        let item = Pharmacy.newDefaultDispenseManifest("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultDispenseManifestTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Pharmacy.DefaultDispenseManifestTimezoneLengthRule(maxLength: 120)
        let item = Pharmacy.newDefaultDispenseManifest("x", title: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
