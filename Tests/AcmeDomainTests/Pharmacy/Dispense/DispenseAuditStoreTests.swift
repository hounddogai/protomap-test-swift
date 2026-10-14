@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseAuditStore = Pharmacy.newMemoryDispenseAuditStore()
        let item = Pharmacy.newDispenseAudit("code-790", title: "title-429")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
