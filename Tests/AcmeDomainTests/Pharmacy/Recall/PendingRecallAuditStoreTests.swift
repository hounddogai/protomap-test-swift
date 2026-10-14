@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingRecallAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingRecallAuditStore = Pharmacy.newMemoryPendingRecallAuditStore()
        let item = Pharmacy.newPendingRecallAudit("code-921", title: "title-650")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
