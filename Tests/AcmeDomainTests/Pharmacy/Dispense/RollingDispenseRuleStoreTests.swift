@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRollingDispenseRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RollingDispenseRuleStore = Pharmacy.newMemoryRollingDispenseRuleStore()
        let item = Pharmacy.newRollingDispenseRule("code-932", label: "label-643")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
