@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionAssignmentStore = Pharmacy.newMemoryInteractionAssignmentStore()
        let item = Pharmacy.newInteractionAssignment("code-790", title: "title-445")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
