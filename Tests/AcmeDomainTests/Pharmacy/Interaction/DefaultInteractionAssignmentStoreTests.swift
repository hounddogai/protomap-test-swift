@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultInteractionAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultInteractionAssignmentStore = Pharmacy.newMemoryDefaultInteractionAssignmentStore()
        let item = Pharmacy.newDefaultInteractionAssignment("code-804", name: "name-828")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
