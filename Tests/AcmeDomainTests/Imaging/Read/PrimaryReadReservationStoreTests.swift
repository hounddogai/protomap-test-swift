@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPrimaryReadReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PrimaryReadReservationStore = Imaging.newMemoryPrimaryReadReservationStore()
        let item = Imaging.newPrimaryReadReservation("code-711", title: "title-934")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
