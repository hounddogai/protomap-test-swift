@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenReviewStore = Labs.newMemorySpecimenReviewStore()
        let item = Labs.newSpecimenReview("code-64", label: "label-23")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
