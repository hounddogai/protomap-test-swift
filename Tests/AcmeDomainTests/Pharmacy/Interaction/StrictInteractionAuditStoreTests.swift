@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictInteractionAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictInteractionAuditStore = Pharmacy.newMemoryStrictInteractionAuditStore()
        let item = Pharmacy.newStrictInteractionAudit("code-821", label: "label-99")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
