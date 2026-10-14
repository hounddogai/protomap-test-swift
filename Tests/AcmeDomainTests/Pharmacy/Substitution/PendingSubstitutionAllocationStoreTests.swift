@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingSubstitutionAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingSubstitutionAllocationStore = Pharmacy.newMemoryPendingSubstitutionAllocationStore()
        let item = Pharmacy.newPendingSubstitutionAllocation("code-552", title: "title-461")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
