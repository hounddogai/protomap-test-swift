@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRollingSubstitutionRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RollingSubstitutionRuleStore = Pharmacy.newMemoryRollingSubstitutionRuleStore()
        let item = Pharmacy.newRollingSubstitutionRule("code-144", name: "name-1")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
