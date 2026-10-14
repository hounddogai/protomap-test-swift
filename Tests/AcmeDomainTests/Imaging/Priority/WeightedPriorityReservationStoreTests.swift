@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWeightedPriorityReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WeightedPriorityReservationStore = Imaging.newMemoryWeightedPriorityReservationStore()
        let item = Imaging.newWeightedPriorityReservation("code-309", label: "label-895")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
