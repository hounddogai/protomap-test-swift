@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacyInteractionAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacyInteractionAuditStore = Pharmacy.newMemoryLegacyInteractionAuditStore()
        let item = Pharmacy.newLegacyInteractionAudit("code-5", name: "name-59")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
