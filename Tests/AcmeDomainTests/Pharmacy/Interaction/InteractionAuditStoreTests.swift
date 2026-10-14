@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionAuditStore = Pharmacy.newMemoryInteractionAuditStore()
        let item = Pharmacy.newInteractionAudit("code-757", name: "name-897")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
