@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledStudyReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledStudyReservationStore = Imaging.newMemoryScheduledStudyReservationStore()
        let item = Imaging.newScheduledStudyReservation("code-941", label: "label-96")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
