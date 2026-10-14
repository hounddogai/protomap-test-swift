@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistReservationStore = Imaging.newMemoryWorklistReservationStore()
        let item = Imaging.newWorklistReservation("code-98", title: "title-943")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
