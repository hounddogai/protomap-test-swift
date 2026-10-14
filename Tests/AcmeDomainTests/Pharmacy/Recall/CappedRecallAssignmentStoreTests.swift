@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryCappedRecallAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.CappedRecallAssignmentStore = Pharmacy.newMemoryCappedRecallAssignmentStore()
        let item = Pharmacy.newCappedRecallAssignment("code-268", title: "title-356")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
