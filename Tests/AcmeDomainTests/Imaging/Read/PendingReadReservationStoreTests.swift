@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPendingReadReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PendingReadReservationStore = Imaging.newMemoryPendingReadReservationStore()
        let item = Imaging.newPendingReadReservation("code-781", label: "label-138")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
