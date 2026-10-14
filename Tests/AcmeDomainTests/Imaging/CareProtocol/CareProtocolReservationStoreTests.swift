@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolReservationStore = Imaging.newMemoryCareProtocolReservationStore()
        let item = Imaging.newCareProtocolReservation("code-320", title: "title-319")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
