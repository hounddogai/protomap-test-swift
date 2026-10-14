@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveInventoryAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveInventoryAuditStore = Pharmacy.newMemoryAdaptiveInventoryAuditStore()
        let item = Pharmacy.newAdaptiveInventoryAudit("code-346", name: "name-605")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
