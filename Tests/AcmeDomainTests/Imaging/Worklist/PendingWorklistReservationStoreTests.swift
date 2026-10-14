@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPendingWorklistReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PendingWorklistReservationStore = Imaging.newMemoryPendingWorklistReservationStore()
        let item = Imaging.newPendingWorklistReservation("code-569", title: "title-816")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
